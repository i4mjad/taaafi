import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { getUserLocale } from './utils/localeHelper';

const STALE_CLAIM_SECONDS = 30;

/**
 * Send notifications when a group update is approved by moderation.
 * Migrated from v1 onCreate to v2 onDocumentUpdated — waits for moderation.
 */
export const sendUpdateNotificationV2 = onDocumentUpdated(
  'group_updates/{updateId}',
  async (event) => {
    try {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();
      if (!before || !after) return;

      // Gate: only fire when moderation just completed with approval
      const wasNotModerated = !before.moderation?.completedAt;
      const isNowApproved = after.moderation?.status === 'approved' && after.moderation?.completedAt;
      if (!wasNotModerated || !isNowApproved) return;

      if (after.isDeleted || after.isHidden) return;

      const updateId = event.params.updateId;
      console.log(`[UPDATE_NOTIFICATION] Moderation approved, sending notifications for: ${updateId}`);

      const db = admin.firestore();
      const docRef = db.collection('group_updates').doc(updateId);

      // Two-phase notification dedupe
      const claimed = await db.runTransaction(async (tx) => {
        const doc = await tx.get(docRef);
        const docData = doc.data();
        if (!docData) return false;

        const claimedAt = docData.notificationClaimedAt?.toDate?.();
        if (docData.notifiedAt) return false;

        if (claimedAt) {
          const ageSeconds = (Date.now() - claimedAt.getTime()) / 1000;
          if (ageSeconds < STALE_CLAIM_SECONDS) return false;
        }

        tx.update(docRef, { notificationClaimedAt: FieldValue.serverTimestamp() });
        return true;
      });

      if (!claimed) {
        console.log(`[UPDATE_NOTIFICATION] Already claimed/sent for ${updateId}`);
        return;
      }

      const { groupId, authorCpId, isAnonymous } = after;

      // Get group data
      const groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        await docRef.update({ notificationClaimedAt: FieldValue.delete() });
        return;
      }
      const groupName = groupDoc.data()!.name || 'Group';

      // Get active members except author
      const membershipsSnapshot = await db.collection('group_memberships')
        .where('groupId', '==', groupId)
        .where('isActive', '==', true)
        .get();

      const memberPromises = membershipsSnapshot.docs
        .filter(doc => doc.data().cpId !== authorCpId)
        .map(async (memberDoc) => {
          const cpId = memberDoc.data().cpId;

          // Use communityProfiles for user mapping (consistent with other functions)
          const profileDoc = await db.collection('communityProfiles').doc(cpId).get();
          if (!profileDoc.exists) return null;

          const userUID = profileDoc.data()?.userUID;
          if (!userUID) return null;

          const userDoc = await db.collection('users').doc(userUID).get();
          if (!userDoc.exists) return null;

          const userData = userDoc.data()!;
          const fcmToken = userData.messagingToken || userData.fcmToken;
          const locale = getUserLocale(userData);

          if (!fcmToken) return null;
          return { fcmToken, locale, cpId };
        });

      const members = (await Promise.all(memberPromises)).filter((m): m is NonNullable<typeof m> => m !== null);

      if (members.length === 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        return;
      }

      // Get author name
      let authorName = 'A member';
      if (!isAnonymous) {
        const authorDoc = await db.collection('communityProfiles').doc(authorCpId).get();
        if (authorDoc.exists) {
          authorName = authorDoc.data()?.displayName || 'A member';
        }
      } else {
        authorName = 'An anonymous member';
      }

      // Send notifications
      const messaging = admin.messaging();
      const results = await Promise.allSettled(
        members.map(async (member) => {
          const title = member.locale === 'arabic'
            ? `تحديث جديد في ${groupName}`
            : `New update in ${groupName}`;
          const body = member.locale === 'arabic'
            ? `${authorName} شارك تحديثاً جديداً`
            : `${authorName} shared an update`;

          await messaging.send({
            token: member.fcmToken,
            notification: { title, body },
            data: {
              type: 'group_update',
              groupId,
              updateId,
              locale: member.locale,
            },
            android: {
              priority: 'high' as const,
              notification: { channelId: 'high_importance_channel', priority: 'high' as const },
            },
            apns: {
              payload: { aps: { alert: { title, body }, badge: 1, sound: 'default' } },
            },
          });
        })
      );

      const successCount = results.filter(r => r.status === 'fulfilled').length;
      if (successCount > 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        console.log(`[UPDATE_NOTIFICATION] Sent ${successCount}/${members.length} for ${updateId}`);
      } else {
        await docRef.update({ notificationClaimedAt: FieldValue.delete() });
        console.error(`[UPDATE_NOTIFICATION] All sends failed for ${updateId}, releasing claim`);
      }

    } catch (error) {
      console.error('[UPDATE_NOTIFICATION] Error:', error);
    }
  }
);

/**
 * Send notification when someone comments on an update.
 * This is NOT moderated content — stays as v1 onCreate.
 */
export const sendCommentNotification = functions.firestore
  .document('update_comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      const commentData = snapshot.data();
      const { updateId, groupId, authorCpId } = commentData;

      // Get update data
      const updateDoc = await admin.firestore().collection('group_updates').doc(updateId).get();
      if (!updateDoc.exists) return;

      const updateAuthorCpId = updateDoc.data()!.authorCpId;
      if (updateAuthorCpId === authorCpId) return; // Don't notify self

      // Get update author's FCM token
      const mappingDoc = await admin.firestore().collection('userProfileMappings').doc(updateAuthorCpId).get();
      if (!mappingDoc.exists) return;

      const userUID = mappingDoc.data()?.userUID;
      if (!userUID) return;

      const userDoc = await admin.firestore().collection('users').doc(userUID).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data()!;
      const fcmToken = userData.messagingToken || userData.fcmToken;
      const locale = getUserLocale(userData);
      if (!fcmToken) return;

      // Get commenter name
      const commenterDoc = await admin.firestore().collection('communityProfiles').doc(authorCpId).get();
      const commenterName = commenterDoc.exists ? commenterDoc.data()?.displayName || 'Someone' : 'Someone';

      const title = locale === 'arabic' ? 'تعليق جديد' : 'New comment';
      const body = locale === 'arabic'
        ? `${commenterName} علق على تحديثك`
        : `${commenterName} commented on your update`;

      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: { type: 'update_comment', groupId, updateId, locale },
        android: {
          priority: 'high' as const,
          notification: { channelId: 'high_importance_channel', priority: 'high' as const },
        },
        apns: {
          payload: { aps: { alert: { title, body }, badge: 1, sound: 'default' } },
        },
      });

      console.log(`[COMMENT_NOTIFICATION] Sent to ${updateAuthorCpId}`);
    } catch (error) {
      console.error('[COMMENT_NOTIFICATION] Error:', error);
    }
  });
