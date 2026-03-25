import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

/**
 * Localization for group message notifications
 */
const translations: Record<string, Record<string, string>> = {
  english: {
    'message-body': '{senderName}: {message}',
    'reply-body': '{senderName} replied to you: {message}',
    'anonymous-user': 'Anonymous',
    'member': 'Member',
    'group': 'Group'
  },
  arabic: {
    'message-body': '{senderName}: {message}',
    'reply-body': '{senderName} رد عليك: {message}',
    'anonymous-user': 'مجهول',
    'member': 'عضو',
    'group': 'مجموعة'
  }
};

function translate(key: string, locale: string, replacements?: Record<string, string>): string {
  const lang = locale === 'arabic' ? 'arabic' : 'english';
  let text = translations[lang][key] || translations.english[key] || key;
  if (replacements) {
    Object.entries(replacements).forEach(([placeholder, value]) => {
      text = text.replace(`{${placeholder}}`, value);
    });
  }
  return text;
}

const STALE_CLAIM_SECONDS = 30;

/**
 * Send push notifications when group messages are approved by moderation.
 * Triggers on document UPDATE (not create) — waits for moderation to complete.
 */
export const sendGroupMessageNotification = onDocumentUpdated(
  'group_messages/{messageId}',
  async (event) => {
    try {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();
      if (!before || !after) return;

      // Gate: only fire when moderation just completed with approval
      const wasNotModerated = !before.moderation?.completedAt;
      const isNowApproved = after.moderation?.status === 'approved' && after.moderation?.completedAt;
      if (!wasNotModerated || !isNowApproved) return;

      // Skip deleted or hidden messages
      if (after.isDeleted || after.isHidden) return;

      const messageId = event.params.messageId;
      logger.info(`[GROUP_MSG_NOTIFICATION] Moderation approved, starting notification for: ${messageId}`);

      const db = getFirestore();
      const docRef = db.collection('group_messages').doc(messageId);

      // Two-phase notification dedupe: claim ownership via transaction
      const claimed = await db.runTransaction(async (tx) => {
        const doc = await tx.get(docRef);
        const docData = doc.data();
        if (!docData) return false;

        const claimedAt = docData.notificationClaimedAt?.toDate?.();
        const notifiedAt = docData.notifiedAt;

        // Already notified — skip
        if (notifiedAt) return false;

        // Check if there's a non-stale claim
        if (claimedAt) {
          const ageSeconds = (Date.now() - claimedAt.getTime()) / 1000;
          if (ageSeconds < STALE_CLAIM_SECONDS) return false; // Active claim, skip
          logger.info(`[GROUP_MSG_NOTIFICATION] Stale claim detected (${ageSeconds}s), re-claiming`);
        }

        tx.update(docRef, { notificationClaimedAt: FieldValue.serverTimestamp() });
        return true;
      });

      if (!claimed) {
        logger.info(`[GROUP_MSG_NOTIFICATION] Notification already claimed/sent for ${messageId}`);
        return;
      }

      const { groupId, senderCpId, body, replyToMessageId = null } = after;

      // Get group info
      const groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        logger.error(`[GROUP_MSG_NOTIFICATION] Group ${groupId} not found`);
        await docRef.update({ notificationClaimedAt: FieldValue.delete() });
        return;
      }
      const groupName = groupDoc.data()!.name || 'مجموعة';

      // Get sender profile
      const senderProfileDoc = await db.collection('communityProfiles').doc(senderCpId).get();
      if (!senderProfileDoc.exists) {
        logger.error(`[GROUP_MSG_NOTIFICATION] Sender profile ${senderCpId} not found`);
        await docRef.update({ notificationClaimedAt: FieldValue.delete() });
        return;
      }
      const senderProfile = senderProfileDoc.data()!;

      // Check for reply target
      let repliedToCpId: string | null = null;
      if (replyToMessageId) {
        const replyDoc = await db.collection('group_messages').doc(replyToMessageId).get();
        if (replyDoc.exists) {
          repliedToCpId = replyDoc.data()!.senderCpId;
        }
      }

      // Get active group members (excluding sender)
      const membersSnapshot = await db.collection('group_memberships')
        .where('groupId', '==', groupId)
        .where('isActive', '==', true)
        .get();

      const memberCpIds = membersSnapshot.docs
        .map(doc => doc.data().cpId)
        .filter(cpId => cpId !== senderCpId);

      if (memberCpIds.length === 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        return;
      }

      // Get community profiles for notification preferences
      const profilesDocs = await Promise.all(
        memberCpIds.map(cpId => db.collection('communityProfiles').doc(cpId).get())
      );

      // Filter eligible members
      const eligibleMembers: Array<{ cpId: string; userUID: string }> = [];
      for (let i = 0; i < profilesDocs.length; i++) {
        const profileDoc = profilesDocs[i];
        if (!profileDoc.exists) continue;
        const profile = profileDoc.data()!;
        const cpId = memberCpIds[i];

        if (profile.isDeleted || profile.accountDeleted) continue;

        const notifPrefs = profile.notificationPreferences || {};
        if (notifPrefs.appNotificationsEnabled === false || notifPrefs.messagesNotifications === false) continue;

        const userUID = profile.userUID;
        if (!userUID) continue;

        eligibleMembers.push({ cpId, userUID });
      }

      if (eligibleMembers.length === 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        return;
      }

      // Get FCM tokens
      const userDocs = await Promise.all(
        eligibleMembers.map(m => db.collection('users').doc(m.userUID).get())
      );

      const usersWithTokens: Array<{ cpId: string; userUID: string; fcmToken: string; locale: string }> = [];
      for (let i = 0; i < userDocs.length; i++) {
        const userDoc = userDocs[i];
        if (!userDoc.exists) continue;
        const user = userDoc.data()!;
        if (user.isDeleted) continue;
        const fcmToken = user.messagingToken || user.fcmToken;
        if (!fcmToken || typeof fcmToken !== 'string') continue;
        usersWithTokens.push({
          cpId: eligibleMembers[i].cpId,
          userUID: eligibleMembers[i].userUID,
          fcmToken,
          locale: user.locale || 'english',
        });
      }

      if (usersWithTokens.length === 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        return;
      }

      // Send notifications
      const messaging = getMessaging();
      const truncatedMessage = body && body.length > 100 ? `${body.substring(0, 100)}...` : (body || '');

      const notificationPromises = usersWithTokens.map(user => {
        const localizedSenderName = senderProfile.isAnonymous
          ? translate('anonymous-user', user.locale)
          : (senderProfile.displayName || translate('member', user.locale));

        const isReplyTarget = repliedToCpId && user.cpId === repliedToCpId;
        const notificationBody = isReplyTarget
          ? translate('reply-body', user.locale, { senderName: localizedSenderName, message: truncatedMessage })
          : translate('message-body', user.locale, { senderName: localizedSenderName, message: truncatedMessage });

        return messaging.send({
          token: user.fcmToken,
          notification: { title: groupName, body: notificationBody },
          data: {
            type: 'group_message',
            groupId,
            messageId,
            senderCpId,
            isReply: isReplyTarget ? 'true' : 'false',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            route: `/groups/${groupId}/chat`,
          },
        });
      });

      const results = await Promise.allSettled(notificationPromises);

      let successCount = 0;
      const failedTokens: string[] = [];
      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          successCount++;
        } else {
          failedTokens.push(usersWithTokens[index].fcmToken);
          logger.error(`[GROUP_MSG_NOTIFICATION] Failed to send to ${usersWithTokens[index].userUID}: ${result.reason}`);
        }
      });

      // Mark notification as sent (phase 2 of dedupe)
      if (successCount > 0) {
        await docRef.update({ notifiedAt: FieldValue.serverTimestamp() });
        logger.info(`[GROUP_MSG_NOTIFICATION] Sent ${successCount}/${usersWithTokens.length} notifications for ${messageId}`);
      } else {
        // All sends failed — release claim so retry can re-attempt
        await docRef.update({ notificationClaimedAt: FieldValue.delete() });
        logger.error(`[GROUP_MSG_NOTIFICATION] All sends failed for ${messageId}, releasing claim`);
      }

      // Clean up invalid tokens
      if (failedTokens.length > 0) {
        await cleanupInvalidTokens(db, failedTokens);
      }

    } catch (error) {
      logger.error(`[GROUP_MSG_NOTIFICATION] Error:`, error);
      // On crash, the stale claim timeout (30s) will allow retry
    }
  }
);

async function cleanupInvalidTokens(db: FirebaseFirestore.Firestore, invalidTokens: string[]) {
  try {
    const batch = db.batch();
    for (const token of invalidTokens) {
      const snap1 = await db.collection('users').where('messagingToken', '==', token).get();
      snap1.docs.forEach(doc => batch.update(doc.ref, { messagingToken: null }));
      const snap2 = await db.collection('users').where('fcmToken', '==', token).get();
      snap2.docs.forEach(doc => batch.update(doc.ref, { fcmToken: null }));
    }
    await batch.commit();
  } catch (error) {
    logger.error('Error cleaning up invalid tokens:', error);
  }
}

/**
 * Handle notification preference changes on community profiles.
 * This function is UNCHANGED — it subscribes/unsubscribes from FCM topics.
 */
export const updateNotificationSubscriptions = onDocumentUpdated(
  'communityProfiles/{cpId}',
  async (event) => {
    try {
      const beforeData = event.data?.before?.data();
      const afterData = event.data?.after?.data();
      if (!beforeData || !afterData) return;

      const cpId = event.params.cpId;
      const beforePrefs = beforeData.notificationPreferences || {};
      const afterPrefs = afterData.notificationPreferences || {};
      const beforeEnabled = beforePrefs.messagesNotifications !== false;
      const afterEnabled = afterPrefs.messagesNotifications !== false;

      if (beforeEnabled === afterEnabled) return;

      const db = getFirestore();
      const messaging = getMessaging();

      const userUID = afterData.userUID;
      if (!userUID) return;

      const userDoc = await db.collection('users').doc(userUID).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()!.messagingToken || userDoc.data()!.fcmToken;
      if (!fcmToken) return;

      const membershipsSnapshot = await db.collection('group_memberships')
        .where('cpId', '==', cpId)
        .where('isActive', '==', true)
        .get();

      const groupIds = membershipsSnapshot.docs.map(doc => doc.data().groupId);
      if (groupIds.length === 0) return;

      const topicOps = groupIds.map(groupId => {
        const topic = `group_${groupId}_messages`;
        return afterEnabled
          ? messaging.subscribeToTopic(fcmToken, topic)
          : messaging.unsubscribeFromTopic(fcmToken, topic);
      });

      await Promise.all(topicOps);
      logger.info(`[NOTIFICATION_PREFS] Updated subscriptions for ${cpId}: ${afterEnabled ? 'subscribed' : 'unsubscribed'}`);
    } catch (error) {
      logger.error(`[NOTIFICATION_PREFS] Error for ${event.params.cpId}:`, error);
    }
  }
);
