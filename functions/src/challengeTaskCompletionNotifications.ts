import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {logger} from 'firebase-functions';
import { getUserLocale } from './utils/localeHelper';
import {getMessaging} from 'firebase-admin/messaging';

// Translation keys for different locales
const translations: Record<string, Record<string, string>> = {
  english: {
    'task-completed-title': 'Challenge Update! 🎯',
    'task-completed-body': '{userName} just completed "{taskName}" in {challengeName}!',
    'task-completed-body-anonymous': 'Someone just completed "{taskName}" in {challengeName}!',
  },
  arabic: {
    'task-completed-title': 'تحديث التحدي! 🎯',
    'task-completed-body': '{userName} أكمل للتو "{taskName}" في {challengeName}!',
    'task-completed-body-anonymous': 'أكمل شخص ما "{taskName}" في {challengeName}!',
  },
};

/**
 * Helper function to translate a message
 */
function translate(
  key: string,
  locale: string,
  replacements?: Record<string, string>
): string {
  const localeTranslations = translations[locale] || translations['english'];
  let text = localeTranslations[key] || translations['english'][key] || key;

  if (replacements) {
    Object.entries(replacements).forEach(([placeholder, value]) => {
      text = text.replace(new RegExp(`{${placeholder}}`, 'g'), value);
    });
  }

  return text;
}

/**
 * Helper function to get user data including locale and FCM token
 */
async function getUserData(cpId: string) {
  const db = admin.firestore();

  try {
    // Get community profile to find userUID
    const profileDoc = await db.collection('communityProfiles').doc(cpId).get();
    if (!profileDoc.exists) {
      logger.warn(`Community profile not found for cpId: ${cpId}`);
      return null;
    }

    const profileData = profileDoc.data();
    const userUID = profileData?.userUID;
    const displayName = profileData?.displayName || profileData?.firstName || 'User';
    const isAnonymous = profileData?.isAnonymous || false;

    if (!userUID) {
      logger.warn(`No userUID found in community profile for cpId: ${cpId}`);
      return null;
    }

    // Get user document to find locale and FCM token
    const userDoc = await db.collection('users').doc(userUID).get();
    if (!userDoc.exists) {
      logger.warn(`User document not found for userUID: ${userUID}`);
      return null;
    }

    const userData = userDoc.data();
    return {
      userUID,
      cpId,
      locale: getUserLocale(userData),
      fcmToken: userData?.messagingToken || userData?.fcmToken,
      displayName,
      isAnonymous,
    };
  } catch (error) {
    logger.error(`Error getting user data for cpId ${cpId}:`, error);
    return null;
  }
}

/**
 * Send notifications when a user completes a challenge task
 * Triggers on updates to challenge_participants documents
 */
export const sendChallengeTaskCompletionNotification = functions.firestore
  .document('challenge_participants/{participationId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();

      // Check if taskCompletions array was updated (new completion added)
      const beforeCompletions = before.taskCompletions || [];
      const afterCompletions = after.taskCompletions || [];

      if (afterCompletions.length <= beforeCompletions.length) {
        logger.info('No new task completions, skipping notification');
        return;
      }

      // Get the new completion(s)
      const newCompletions = afterCompletions.slice(beforeCompletions.length);
      if (newCompletions.length === 0) {
        logger.info('No new completions found');
        return;
      }

      // Process the most recent completion
      const latestCompletion = newCompletions[newCompletions.length - 1];
      const taskId = latestCompletion.taskId;
      const completedByCpId = after.cpId;
      const challengeId = after.challengeId;
      const groupId = after.groupId;

      logger.info(`🎯 Task completion detected:`, {
        challengeId,
        groupId,
        taskId,
        completedBy: completedByCpId,
      });

      // Get challenge details
      const challengeDoc = await admin.firestore()
        .collection('group_challenges')
        .doc(challengeId)
        .get();

      if (!challengeDoc.exists) {
        logger.warn(`Challenge not found: ${challengeId}`);
        return;
      }

      const challengeData = challengeDoc.data()!;
      const challengeName = challengeData.name || 'a challenge';
      const tasks = challengeData.tasks || [];
      const task = tasks.find((t: any) => t.id === taskId);
      const taskName = task?.name || 'a task';

      logger.info(`📋 Challenge: "${challengeName}", Task: "${taskName}"`);

      // Get user who completed the task
      const completedByUser = await getUserData(completedByCpId);
      if (!completedByUser) {
        logger.warn(`Could not get user data for cpId: ${completedByCpId}`);
        return;
      }

      const userName = completedByUser.isAnonymous
        ? null
        : completedByUser.displayName;

      logger.info(`👤 Completed by: ${userName || 'Anonymous'}`);

      // Get all active group members (not just challenge participants)
      const membershipsSnapshot = await admin.firestore()
        .collection('group_memberships')
        .where('groupId', '==', groupId)
        .where('isActive', '==', true)
        .get();

      logger.info(`👥 Found ${membershipsSnapshot.size} active group members`);

      // Get FCM tokens for all members except the one who completed
      const memberPromises = membershipsSnapshot.docs
        .filter((doc) => doc.data().cpId !== completedByCpId)
        .map(async (memberDoc) => {
          const memberData = memberDoc.data();
          return await getUserData(memberData.cpId);
        });

      const members = (await Promise.all(memberPromises))
        .filter((m) => m !== null && m!.fcmToken);

      logger.info(`🎯 ${members.length} members with FCM tokens to notify`);

      if (members.length === 0) {
        logger.info('📭 No members to notify');
        return;
      }

      // Send personalized notifications based on user locale
      const messaging = getMessaging();
      const notificationPromises = members.map(async (member) => {
        if (!member) return null;

        const locale = member.locale || 'english';
        const isAnonymousCompletion = !userName;

        const titleKey = 'task-completed-title';
        const bodyKey = isAnonymousCompletion
          ? 'task-completed-body-anonymous'
          : 'task-completed-body';

        const title = translate(titleKey, locale);
        const body = translate(bodyKey, locale, {
          userName: userName || '',
          taskName,
          challengeName,
        });

        logger.info(`📨 Sending to ${member.cpId} (${locale}): ${title}`);

        const message = {
          token: member.fcmToken!,
          notification: {
            title,
            body,
          },
          data: {
            type: 'challenge_task_completion',
            groupId,
            challengeId,
            taskId,
            completedBy: completedByCpId,
            locale,
          },
          android: {
            notification: {
              channelId: 'challenge_updates',
              icon: '@mipmap/ic_launcher',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title,
                  body,
                },
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        try {
          const response = await messaging.send(message);
          logger.info(`✅ Notification sent to ${member.cpId}: ${response}`);
          return {cpId: member.cpId, success: true};
        } catch (error) {
          logger.error(`❌ Failed to send to ${member.cpId}:`, error);
          return {cpId: member.cpId, success: false, error};
        }
      });

      const results = await Promise.all(notificationPromises);
      const successful = results.filter((r) => r?.success).length;
      const failed = results.filter((r) => r && !r.success).length;

      logger.info(`✅ Notifications sent: ${successful} successful, ${failed} failed`);
    } catch (error) {
      logger.error('❌ Error in sendChallengeTaskCompletionNotification:', error);
    }
  });

