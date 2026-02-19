import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: onPostDeleteCascade
 * 
 * Trigger: on delete of forumPosts/{postId}
 * 
 * Purpose: Clean up all related data when a post is deleted:
 * - Delete attachment subcollection documents
 * - Delete nested vote documents
 * - Delete Storage files
 * - Revoke active invites
 */
export const onPostDeleteCascade = functions
  .region('us-central1')
  .firestore
  .document('forumPosts/{postId}')
  .onDelete(async (snap, context) => {
    const { postId } = context.params;
    const db = admin.firestore();
    const storage = admin.storage().bucket();
    
    try {
      console.log(`[CASCADE] Starting cascade delete for post ${postId}`);
      
      // 1. Delete attachment documents and their subcollections
      await deleteAttachmentsAndSubcollections(db, postId);
      
      // 2. Delete Storage files
      await deleteStorageFiles(storage, postId);
      
      console.log(`[CASCADE] Cascade delete completed for post ${postId}`);
      
    } catch (error) {
      console.error(`[CASCADE] Error in cascade delete for post ${postId}:`, error);
      throw error;
    }
  });

async function deleteAttachmentsAndSubcollections(
  db: admin.firestore.Firestore,
  postId: string
): Promise<void> {
  try {
    console.log(`[CASCADE] Deleting attachments for post ${postId}`);
    
    // Get all attachments
    const attachmentsSnap = await db
      .collection('forumPosts')
      .doc(postId)
      .collection('attachments')
      .get();
    
    // Delete each attachment and its subcollections
    for (const attachmentDoc of attachmentsSnap.docs) {
      const attachmentId = attachmentDoc.id;
      const attachmentData = attachmentDoc.data();
      
      // Delete votes subcollection for polls
      if (attachmentData.type === 'poll') {
        const votesSnap = await attachmentDoc.ref.collection('votes').get();
        const batch = db.batch();
        
        votesSnap.docs.forEach((voteDoc) => {
          batch.delete(voteDoc.ref);
        });
        
        if (!votesSnap.empty) {
          await batch.commit();
          console.log(`[CASCADE] Deleted ${votesSnap.docs.length} votes for poll ${attachmentId}`);
        }
      }
      
      // Delete counters subcollection if using shards (optional feature)
      try {
        const countersSnap = await attachmentDoc.ref.collection('counters').get();
        if (!countersSnap.empty) {
          const countersBatch = db.batch();
          countersSnap.docs.forEach((counterDoc) => {
            countersBatch.delete(counterDoc.ref);
          });
          await countersBatch.commit();
          console.log(`[CASCADE] Deleted ${countersSnap.docs.length} counter shards for ${attachmentId}`);
        }
      } catch (countersError) {
        // Counters collection may not exist, continue
        console.log(`[CASCADE] No counters collection for ${attachmentId}`);
      }
      
      // Revoke group invites
      if (attachmentData.type === 'group_invite' && attachmentData.status === 'active') {
        await db
          .collection('forumPosts')
          .doc(postId)
          .collection('attachments')
          .doc(attachmentId)
          .update({
            status: 'revoked',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        console.log(`[CASCADE] Revoked group invite ${attachmentId}`);
      }
    }
    
    // Delete all attachment documents
    if (!attachmentsSnap.empty) {
      const attachmentsBatch = db.batch();
      attachmentsSnap.docs.forEach((attachmentDoc) => {
        attachmentsBatch.delete(attachmentDoc.ref);
      });
      
      await attachmentsBatch.commit();
      console.log(`[CASCADE] Deleted ${attachmentsSnap.docs.length} attachment documents`);
    }
    
  } catch (error) {
    console.error(`[CASCADE] Error deleting attachments:`, error);
    throw error;
  }
}

async function deleteStorageFiles(
  bucket: any,
  postId: string
): Promise<void> {
  try {
    console.log(`[CASCADE] Deleting storage files for post ${postId}`);
    
    // Delete files under images/{postId}/
    const [files] = await bucket.getFiles({ 
      prefix: `images/${postId}/` 
    });
    
    if (files.length > 0) {
      await Promise.all(
        files.map((file) => 
          file.delete().catch((error) => {
            console.log(`[CASCADE] Warning: Could not delete ${file.name}: ${error.message}`);
          })
        )
      );
      console.log(`[CASCADE] Deleted ${files.length} storage files`);
    } else {
      console.log(`[CASCADE] No storage files found for post ${postId}`);
    }
    
  } catch (error) {
    console.error(`[CASCADE] Error deleting storage files:`, error);
    throw error;
  }
}
