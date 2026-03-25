import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { moderateSnapshot } from './pipeline';
import { ModerationConfig } from './types';

const STUCK_THRESHOLD_MS = 90 * 1000; // 90 seconds
const MAX_DOCS_PER_RUN = 20;

interface CollectionConfig {
  collection: string;
  moderationConfig: ModerationConfig;
}

const MODERATED_COLLECTIONS: CollectionConfig[] = [
  {
    collection: 'group_messages',
    moderationConfig: {
      textExtractor: (data) => data.body || '',
      authorIdField: 'senderCpId',
      contentType: 'group_message',
      autoHideOnFlag: false,
    },
  },
  {
    collection: 'forumPosts',
    moderationConfig: {
      textExtractor: (data) => `${data.title || ''}\n${data.body || ''}`.trim(),
      authorIdField: 'authorCPId',
      contentType: 'forum_post',
      autoHideOnFlag: true,
    },
  },
  {
    collection: 'comments',
    moderationConfig: {
      textExtractor: (data) => data.body || '',
      authorIdField: 'authorCPId',
      contentType: 'comment',
      autoHideOnFlag: true,
    },
  },
  {
    collection: 'group_updates',
    moderationConfig: {
      textExtractor: (data) => `${data.title || ''}\n${data.content || ''}`.trim(),
      authorIdField: 'authorCpId',
      contentType: 'group_update',
      autoHideOnFlag: true,
    },
  },
];

/**
 * Scheduled function that retries stuck moderation for documents
 * that have been in 'pending' status for more than 90 seconds.
 * Runs every 5 minutes.
 */
export const retryStuckMessages = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async () => {
    const db = admin.firestore();
    const cutoff = new Date(Date.now() - STUCK_THRESHOLD_MS);
    let totalProcessed = 0;

    console.log(`[RETRY] Starting stuck message sweep (cutoff: ${cutoff.toISOString()})`);

    for (const { collection, moderationConfig } of MODERATED_COLLECTIONS) {
      if (totalProcessed >= MAX_DOCS_PER_RUN) break;

      try {
        const snapshot = await db.collection(collection)
          .where('moderation.status', '==', 'pending')
          .where('createdAt', '<', cutoff)
          .limit(MAX_DOCS_PER_RUN - totalProcessed)
          .get();

        if (snapshot.empty) continue;

        console.log(`[RETRY] Found ${snapshot.size} stuck documents in ${collection}`);

        for (const doc of snapshot.docs) {
          if (totalProcessed >= MAX_DOCS_PER_RUN) break;

          try {
            console.log(`[RETRY] Retrying moderation for ${collection}/${doc.id}`);
            await moderateSnapshot(doc.ref, doc.data(), moderationConfig);
            totalProcessed++;
          } catch (error) {
            console.error(`[RETRY] Failed to retry ${collection}/${doc.id}:`, error);
            // moderateSnapshot handles its own error path (classification_failed → manual_review)
            // If it throws, something is deeply wrong — skip this doc
            totalProcessed++;
          }
        }
      } catch (error) {
        console.error(`[RETRY] Error querying ${collection}:`, error);
      }
    }

    console.log(`[RETRY] Sweep complete: processed ${totalProcessed} documents`);
  },
);
