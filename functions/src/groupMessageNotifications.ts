import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

/**
 * Localization for group message notifications
 */
const translations = {
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

/**
 * Helper function to translate text based on locale
 */
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

/**
 * Cloud Function to send push notifications when new group messages are created
 * Triggers on: /group_messages/{messageId} document creation
 */
export const sendGroupMessageNotification = onDocumentCreated(
  'group_messages/{messageId}',
  async (event) => {
    try {
      logger.info(`🚀 [GROUP_MSG_NOTIFICATION] Starting notification process for message: ${event.params.messageId}`);
      
      const messageData = event.data?.data();
      if (!messageData) {
        logger.warn('❌ [GROUP_MSG_NOTIFICATION] No message data found');
        return;
      }
      
      logger.info(`📋 [GROUP_MSG_NOTIFICATION] Message data:`, {
        messageId: event.params.messageId,
        groupId: messageData.groupId,
        senderCpId: messageData.senderCpId,
        hasReply: !!messageData.replyToMessageId,
        bodyLength: messageData.body?.length || 0,
        isDeleted: messageData.isDeleted,
        isHidden: messageData.isHidden,
        moderationStatus: messageData.moderation?.status
      });

      const {
        groupId,
        senderCpId,
        body,
        replyToMessageId = null,
        isDeleted = false,
        isHidden = false,
        moderation = {}
      } = messageData;

      // Skip notifications for deleted, hidden, or blocked messages
      if (isDeleted || isHidden || moderation?.status === 'blocked') {
        logger.info(`⏭️ [GROUP_MSG_NOTIFICATION] Skipping notification - isDeleted: ${isDeleted}, isHidden: ${isHidden}, moderationStatus: ${moderation?.status}`);
        return;
      }

      const db = getFirestore();

      // Get group information
      logger.info(`🏠 [GROUP_MSG_NOTIFICATION] Fetching group data for: ${groupId}`);
      const groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        logger.error(`❌ [GROUP_MSG_NOTIFICATION] Group ${groupId} not found`);
        return;
      }

      const groupData = groupDoc.data()!;
      const groupName = groupData.name || 'مجموعة';
      logger.info(`✅ [GROUP_MSG_NOTIFICATION] Group found: ${groupName}`);

      // Get sender's community profile for display name
      logger.info(`👤 [GROUP_MSG_NOTIFICATION] Fetching sender profile: ${senderCpId}`);
      const senderProfileDoc = await db.collection('communityProfiles').doc(senderCpId).get();
      if (!senderProfileDoc.exists) {
        logger.error(`❌ [GROUP_MSG_NOTIFICATION] Sender profile ${senderCpId} not found`);
        return;
      }

      const senderProfile = senderProfileDoc.data()!;
      logger.info(`✅ [GROUP_MSG_NOTIFICATION] Sender profile found:`, {
        displayName: senderProfile.displayName,
        isAnonymous: senderProfile.isAnonymous,
        isDeleted: senderProfile.isDeleted
      });
      
      // Check if this is a reply to another message
      let repliedToCpId: string | null = null;
      if (replyToMessageId) {
        logger.info(`💬 [GROUP_MSG_NOTIFICATION] This is a reply to message: ${replyToMessageId}`);
        const replyToMessageDoc = await db.collection('group_messages').doc(replyToMessageId).get();
        if (replyToMessageDoc.exists) {
          const replyToMessageData = replyToMessageDoc.data()!;
          repliedToCpId = replyToMessageData.senderCpId;
          logger.info(`🎯 [GROUP_MSG_NOTIFICATION] Reply target found: ${repliedToCpId}`);
        } else {
          logger.warn(`⚠️ [GROUP_MSG_NOTIFICATION] Original message not found: ${replyToMessageId}`);
        }
      }

      // Get active group members (excluding sender)
      logger.info(`👥 [GROUP_MSG_NOTIFICATION] Fetching active group members for group: ${groupId}`);
      const membersSnapshot = await db.collection('group_memberships')
        .where('groupId', '==', groupId)
        .where('isActive', '==', true)
        .get();

      if (membersSnapshot.empty) {
        logger.info('📭 [GROUP_MSG_NOTIFICATION] No active members found for group');
        return;
      }

      logger.info(`👥 [GROUP_MSG_NOTIFICATION] Found ${membersSnapshot.docs.length} active members`);

      // Get member cpIds (excluding sender)
      const memberCpIds = membersSnapshot.docs
        .map(doc => doc.data().cpId)
        .filter(cpId => cpId !== senderCpId);

      logger.info(`🔍 [GROUP_MSG_NOTIFICATION] Members after excluding sender: ${memberCpIds.length} (excluded: ${senderCpId})`);

      if (memberCpIds.length === 0) {
        logger.info('📭 [GROUP_MSG_NOTIFICATION] No members to notify (excluding sender)');
        return;
      }

      // Batch get community profiles for notification preferences
      logger.info(`📊 [GROUP_MSG_NOTIFICATION] Fetching community profiles for ${memberCpIds.length} members: ${memberCpIds.join(', ')}`);
      const profilesPromises = memberCpIds.map(cpId => 
        db.collection('communityProfiles').doc(cpId).get()
      );
      const profilesDocs = await Promise.all(profilesPromises);

      // Filter eligible members for notifications
      const eligibleMembers: Array<{ cpId: string; userUID: string }> = [];
      logger.info(`🔍 [GROUP_MSG_NOTIFICATION] Filtering profiles for notification eligibility...`);

      for (let i = 0; i < profilesDocs.length; i++) {
        const profileDoc = profilesDocs[i];
        if (!profileDoc.exists) {
          logger.warn(`⚠️ [GROUP_MSG_NOTIFICATION] Community profile not found for index ${i}`);
          continue;
        }

        const profile = profileDoc.data()!;
        const cpId = memberCpIds[i];

        logger.info(`👤 [GROUP_MSG_NOTIFICATION] Checking profile ${cpId}:`, {
          isDeleted: profile.isDeleted,
          accountDeleted: profile.accountDeleted,
          hasUserUID: !!profile.userUID,
          notificationPrefs: profile.notificationPreferences
        });

        // Check if profile is deleted or account is deleted
        if (profile.isDeleted || profile.accountDeleted) {
          logger.info(`❌ [GROUP_MSG_NOTIFICATION] Profile ${cpId} is deleted (isDeleted: ${profile.isDeleted}, accountDeleted: ${profile.accountDeleted})`);
          continue;
        }

        // Check notification preferences
        const notificationPrefs = profile.notificationPreferences || {};
        const appNotificationsEnabled = notificationPrefs.appNotificationsEnabled !== false;
        const messagesNotifications = notificationPrefs.messagesNotifications !== false;

        if (!appNotificationsEnabled || !messagesNotifications) {
          logger.info(`🔕 [GROUP_MSG_NOTIFICATION] Notifications disabled for cpId: ${cpId} (app: ${appNotificationsEnabled}, messages: ${messagesNotifications})`);
          continue;
        }

        // Get userUID for FCM token lookup (not accountId)
        const userUID = profile.userUID;
        if (!userUID) {
          logger.warn(`⚠️ [GROUP_MSG_NOTIFICATION] No userUID found for cpId: ${cpId}`);
          continue;
        }

        logger.info(`✅ [GROUP_MSG_NOTIFICATION] Profile ${cpId} is eligible for notifications (userUID: ${userUID})`);
        eligibleMembers.push({ cpId, userUID });
      }

      logger.info(`📋 [GROUP_MSG_NOTIFICATION] Eligible members summary: ${eligibleMembers.length} out of ${memberCpIds.length} total members`);

      if (eligibleMembers.length === 0) {
        logger.info('📭 [GROUP_MSG_NOTIFICATION] No eligible members for notifications');
        return;
      }

      // Get user data for eligible members from users collection
      logger.info(`🔑 [GROUP_MSG_NOTIFICATION] Fetching user data for ${eligibleMembers.length} eligible members`);
      const tokenPromises = eligibleMembers.map(member => 
        db.collection('users').doc(member.userUID).get()
      );
      const userDocs = await Promise.all(tokenPromises);

      const eligibleUsersWithTokens: Array<{
        userUID: string;
        cpId: string;
        fcmToken: string;
        locale: string;
      }> = [];

      for (let i = 0; i < userDocs.length; i++) {
        const userDoc = userDocs[i];
        const member = eligibleMembers[i];
        
        if (!userDoc.exists) {
          logger.warn(`⚠️ [GROUP_MSG_NOTIFICATION] User document not found for userUID: ${member.userUID} (cpId: ${member.cpId})`);
          continue;
        }

        const user = userDoc.data()!;
        
        logger.info(`🔑 [GROUP_MSG_NOTIFICATION] Processing user ${member.userUID} (cpId: ${member.cpId}):`, {
          hasMessagingToken: !!(user.messagingToken || user.fcmToken),
          locale: user.locale,
          isDeleted: user.isDeleted
        });
        
        // Check if user account is deleted (if such field exists)
        if (user.isDeleted) {
          logger.info(`❌ [GROUP_MSG_NOTIFICATION] User account is deleted: ${member.userUID}`);
          continue;
        }

        const fcmToken = user.messagingToken || user.fcmToken; // Support both field names
        const locale = user.locale || 'english'; // Default to English if not set
        
        if (fcmToken && typeof fcmToken === 'string') {
          logger.info(`✅ [GROUP_MSG_NOTIFICATION] User ${member.userUID} has valid FCM token (locale: ${locale})`);
          eligibleUsersWithTokens.push({
            userUID: member.userUID,
            cpId: member.cpId,
            fcmToken,
            locale
          });
        } else {
          logger.warn(`⚠️ [GROUP_MSG_NOTIFICATION] No valid FCM token for user: ${member.userUID}`);
        }
      }

      logger.info(`🎯 [GROUP_MSG_NOTIFICATION] Final eligible users with tokens: ${eligibleUsersWithTokens.length}`);

      if (eligibleUsersWithTokens.length === 0) {
        logger.info('📭 [GROUP_MSG_NOTIFICATION] No valid FCM tokens found');
        return;
      }

      // Send personalized notifications based on user locale and reply status
      logger.info(`📨 [GROUP_MSG_NOTIFICATION] Preparing ${eligibleUsersWithTokens.length} personalized notifications...`);
      const messaging = getMessaging();
      const notificationPromises: Promise<any>[] = [];

      for (const user of eligibleUsersWithTokens) {
        // Get localized sender display name
        const localizedSenderName = senderProfile.isAnonymous 
          ? translate('anonymous-user', user.locale)
          : (senderProfile.displayName || translate('member', user.locale));

        // Title is always just the group name
        const notificationTitle = groupName;
        
        // Body format depends on whether it's a reply or regular message
        let notificationBody: string;
        const truncatedMessage = body.length > 100 ? `${body.substring(0, 100)}...` : body;
        
        // Check if this user is the one being replied to
        if (repliedToCpId && user.cpId === repliedToCpId) {
          // Special reply notification body
          notificationBody = translate('reply-body', user.locale, {
            senderName: localizedSenderName,
            message: truncatedMessage
          });
          logger.info(`💬 [GROUP_MSG_NOTIFICATION] Reply notification for ${user.cpId}: "${notificationBody}"`);
        } else {
          // Regular group message notification body
          notificationBody = translate('message-body', user.locale, {
            senderName: localizedSenderName,
            message: truncatedMessage
          });
          logger.info(`📢 [GROUP_MSG_NOTIFICATION] Group notification for ${user.cpId} (${user.locale}): "${notificationBody}"`);
        }

        // Send individual notification
        const message = {
          token: user.fcmToken,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: 'group_message',
            groupId: groupId,
            messageId: event.params.messageId,
            senderCpId: senderCpId,
            isReply: repliedToCpId && user.cpId === repliedToCpId ? 'true' : 'false',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            route: `/groups/${groupId}/chat`,
          },
        };

        notificationPromises.push(messaging.send(message));
      }

      // Send all notifications in parallel
      logger.info(`🚀 [GROUP_MSG_NOTIFICATION] Sending ${notificationPromises.length} notifications in parallel...`);
      const results = await Promise.allSettled(notificationPromises);
      
      let successCount = 0;
      let failureCount = 0;
      const failedTokens: string[] = [];

      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          successCount++;
          logger.info(`✅ [GROUP_MSG_NOTIFICATION] Successfully sent to user ${eligibleUsersWithTokens[index].userUID} (cpId: ${eligibleUsersWithTokens[index].cpId})`);
        } else {
          failureCount++;
          failedTokens.push(eligibleUsersWithTokens[index].fcmToken);
          logger.error(`❌ [GROUP_MSG_NOTIFICATION] Failed to send to user ${eligibleUsersWithTokens[index].userUID} (cpId: ${eligibleUsersWithTokens[index].cpId}): ${result.reason}`);
        }
      });

      logger.info(`📊 [GROUP_MSG_NOTIFICATION] Final results: ${successCount} success, ${failureCount} failures out of ${eligibleUsersWithTokens.length} total`);
      
      if (failedTokens.length > 0) {
        logger.info(`🧹 [GROUP_MSG_NOTIFICATION] Cleaning up ${failedTokens.length} invalid FCM tokens...`);
        await cleanupInvalidTokens(db, failedTokens);
      }

      logger.info(`🎉 [GROUP_MSG_NOTIFICATION] Notification process completed for message: ${event.params.messageId}`);

    } catch (error) {
      logger.error(`💥 [GROUP_MSG_NOTIFICATION] Error sending group message notification for ${event.params.messageId}:`, error);
    }
  }
);

/**
 * Helper function to clean up invalid FCM tokens
 */
async function cleanupInvalidTokens(db: FirebaseFirestore.Firestore, invalidTokens: string[]) {
  if (invalidTokens.length === 0) return;

  try {
    const batch = db.batch();
    
    for (const token of invalidTokens) {
              // Find users with this invalid token
        const usersSnapshot = await db.collection('users')
          .where('messagingToken', '==', token)
          .get();

        usersSnapshot.docs.forEach(doc => {
          batch.update(doc.ref, { messagingToken: null });
        });

        // Also check for fcmToken field name
        const usersSnapshot2 = await db.collection('users')
          .where('fcmToken', '==', token)
          .get();

        usersSnapshot2.docs.forEach(doc => {
          batch.update(doc.ref, { fcmToken: null });
        });
    }

    await batch.commit();
    logger.info(`Cleaned up ${invalidTokens.length} invalid FCM tokens`);
  } catch (error) {
    logger.error('Error cleaning up invalid tokens:', error);
  }
}

/**
 * Cloud Function to handle when users enable/disable message notifications
 * Triggers on: /communityProfiles/{cpId} document updates
 */
export const updateNotificationSubscriptions = onDocumentUpdated(
  'communityProfiles/{cpId}',
  async (event) => {
    try {
      logger.info(`🔔 [NOTIFICATION_PREFS] Profile updated: ${event.params.cpId}`);
      
      const beforeData = event.data?.before?.data();
      const afterData = event.data?.after?.data();
      
      if (!beforeData || !afterData) {
        logger.warn(`⚠️ [NOTIFICATION_PREFS] Missing before/after data for ${event.params.cpId}`);
        return;
      }

      const cpId = event.params.cpId;
      
      // Check if notification preferences changed
      const beforePrefs = beforeData.notificationPreferences || {};
      const afterPrefs = afterData.notificationPreferences || {};
      
      const beforeEnabled = beforePrefs.messagesNotifications !== false;
      const afterEnabled = afterPrefs.messagesNotifications !== false;
      
      logger.info(`📊 [NOTIFICATION_PREFS] Preference change for ${cpId}:`, {
        before: beforeEnabled,
        after: afterEnabled,
        changed: beforeEnabled !== afterEnabled
      });
      
      if (beforeEnabled === afterEnabled) {
        logger.info(`⏭️ [NOTIFICATION_PREFS] No change in message notifications for ${cpId}`);
        return; // No change in message notification preference
      }

      const db = getFirestore();
      const messaging = getMessaging();
      
      // Get user's account for FCM token using userUID
      const userUID = afterData.userUID;
      if (!userUID) {
        logger.warn(`⚠️ [NOTIFICATION_PREFS] No userUID found for cpId: ${cpId}`);
        return;
      }

      logger.info(`🔑 [NOTIFICATION_PREFS] Fetching user data for userUID: ${userUID}`);
      const userDoc = await db.collection('users').doc(userUID).get();
      if (!userDoc.exists) {
        logger.warn(`⚠️ [NOTIFICATION_PREFS] User document not found for userUID: ${userUID}`);
        return;
      }

      const user = userDoc.data()!;
      const fcmToken = user.messagingToken || user.fcmToken; // Support both field names
      if (!fcmToken) {
        logger.warn(`⚠️ [NOTIFICATION_PREFS] No FCM token found for userUID: ${userUID}`);
        return;
      }

      logger.info(`✅ [NOTIFICATION_PREFS] User data found for ${userUID} with FCM token`);

      // Get all groups user is member of
      logger.info(`👥 [NOTIFICATION_PREFS] Fetching group memberships for cpId: ${cpId}`);
      const membershipsSnapshot = await db.collection('group_memberships')
        .where('cpId', '==', cpId)
        .where('isActive', '==', true)
        .get();

      const groupIds = membershipsSnapshot.docs.map(doc => doc.data().groupId);
      logger.info(`🏠 [NOTIFICATION_PREFS] Found ${groupIds.length} active group memberships: ${groupIds.join(', ')}`);

      if (groupIds.length === 0) {
        logger.info(`📭 [NOTIFICATION_PREFS] No active group memberships found for ${cpId}`);
        return;
      }

      // Subscribe/unsubscribe from group topics
      const action = afterEnabled ? 'subscribing to' : 'unsubscribing from';
      logger.info(`🔔 [NOTIFICATION_PREFS] ${action} ${groupIds.length} group topics for ${cpId}`);
      
      const topicOperations = groupIds.map(groupId => {
        const topic = `group_${groupId}_messages`;
        logger.info(`📝 [NOTIFICATION_PREFS] ${afterEnabled ? 'Subscribing to' : 'Unsubscribing from'} topic: ${topic}`);
        
        if (afterEnabled) {
          return messaging.subscribeToTopic(fcmToken, topic);
        } else {
          return messaging.unsubscribeFromTopic(fcmToken, topic);
        }
      });

      await Promise.all(topicOperations);
      
      logger.info(`✅ [NOTIFICATION_PREFS] Successfully updated topic subscriptions for cpId: ${cpId} (${afterEnabled ? 'subscribed' : 'unsubscribed'})`);

    } catch (error) {
      logger.error(`💥 [NOTIFICATION_PREFS] Error updating notification subscriptions for ${event.params.cpId}:`, error);
    }
  }
);
