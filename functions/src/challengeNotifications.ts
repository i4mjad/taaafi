import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions';
import {getFirestore} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {getUserLocale} from './utils/localeHelper';

// Translation keys for challenge notifications
const translations: Record<string, Record<string, string>> = {
  english: {
    'daily-reminder-title': 'Challenge Reminder',
    'daily-reminder-body': "Don't forget to complete your tasks today!",
    'milestone-title': 'Milestone Reached!',
    'milestone-body': "You've reached {milestone}% in your challenge!",
    'challenge-complete-title': 'Challenge Completed!',
    'challenge-complete-body': 'Congratulations! You\'ve completed "{challengeName}"',
    'rank-update-title': 'Rank Update!',
    'rank-update-body': "You moved up {rankChange} positions! You're now #{newRank}",
    'challenge-ending-soon-title': 'Challenge Ending Soon!',
    'challenge-ending-soon-body': '"{challengeName}" ends in {timeText}',
  },
  arabic: {
    'daily-reminder-title': 'تذكير بالتحدي',
    'daily-reminder-body': 'لا تنسَ إكمال مهامك اليوم!',
    'milestone-title': 'تم الوصول لمرحلة مهمة!',
    'milestone-body': 'لقد وصلت إلى {milestone}% في تحديك!',
    'challenge-complete-title': 'اكتمل التحدي!',
    'challenge-complete-body': 'تهانينا! لقد أكملت "{challengeName}"',
    'rank-update-title': 'تحديث الترتيب!',
    'rank-update-body': 'تقدمت {rankChange} مراكز! أنت الآن #{newRank}',
    'challenge-ending-soon-title': 'التحدي على وشك الانتهاء!',
    'challenge-ending-soon-body': '"{challengeName}" ينتهي خلال {timeText}',
  },
};

function translate(
  key: string,
  locale: string,
  replacements?: Record<string, string | number>,
): string {
  const localeTranslations = translations[locale] || translations['english'];
  let text = localeTranslations[key] || translations['english'][key] || key;

  if (replacements) {
    Object.entries(replacements).forEach(([placeholder, value]) => {
      text = text.replace(new RegExp(`\\{${placeholder}\\}`, 'g'), String(value));
    });
  }

  return text;
}

/**
 * Look up a recipient's FCM token and locale via communityProfiles -> users
 */
async function getRecipientData(cpId: string) {
  const db = getFirestore();

  const profileDoc = await db.collection('communityProfiles').doc(cpId).get();
  if (!profileDoc.exists) {
    logger.warn(`Community profile not found for cpId: ${cpId}`);
    return null;
  }

  const profileData = profileDoc.data();
  const userUID = profileData?.userUID;
  if (!userUID) {
    logger.warn(`No userUID found for cpId: ${cpId}`);
    return null;
  }

  const userDoc = await db.collection('users').doc(userUID).get();
  if (!userDoc.exists) {
    logger.warn(`User document not found for userUID: ${userUID}`);
    return null;
  }

  const userData = userDoc.data();
  return {
    userUID,
    locale: getUserLocale(userData),
    fcmToken: userData?.messagingToken || userData?.fcmToken,
  };
}

/**
 * Build notification content based on type
 */
function buildNotification(
  type: string,
  locale: string,
  data: Record<string, any>,
): {title: string; body: string} {
  switch (type) {
    case 'daily_reminder':
      return {
        title: translate('daily-reminder-title', locale),
        body: translate('daily-reminder-body', locale),
      };
    case 'milestone':
      return {
        title: translate('milestone-title', locale),
        body: translate('milestone-body', locale, {
          milestone: data.milestone || 0,
        }),
      };
    case 'challenge_complete':
      return {
        title: translate('challenge-complete-title', locale),
        body: translate('challenge-complete-body', locale, {
          challengeName: data.challengeName || '',
        }),
      };
    case 'rank_update':
      return {
        title: translate('rank-update-title', locale),
        body: translate('rank-update-body', locale, {
          rankChange: data.rankChange || 0,
          newRank: data.newRank || 0,
        }),
      };
    case 'challenge_ending_soon':
      return {
        title: translate('challenge-ending-soon-title', locale),
        body: translate('challenge-ending-soon-body', locale, {
          challengeName: data.challengeName || '',
          timeText: data.timeText || '',
        }),
      };
    default:
      logger.warn(`Unknown notification type: ${type}`);
      return {title: 'Challenge Update', body: ''};
  }
}

/**
 * Callable function: send a challenge notification to a specific recipient
 *
 * Accepts: { type, challengeId, recipientCpId, data? }
 * Types: daily_reminder, milestone, challenge_complete, rank_update, challenge_ending_soon
 */
export const sendChallengeNotification = onCall(async (request) => {
  const {type, challengeId, recipientCpId, data} = request.data;

  if (!type || !challengeId || !recipientCpId) {
    throw new HttpsError(
      'invalid-argument',
      'type, challengeId, and recipientCpId are required',
    );
  }

  logger.info(`Sending challenge notification`, {type, challengeId, recipientCpId});

  const recipient = await getRecipientData(recipientCpId);
  if (!recipient || !recipient.fcmToken) {
    logger.warn(`No FCM token available for cpId: ${recipientCpId}`);
    return {success: false, reason: 'no_fcm_token'};
  }

  const {title, body} = buildNotification(type, recipient.locale, data || {});

  const message = {
    token: recipient.fcmToken,
    notification: {title, body},
    data: {
      type: `challenge_${type}`,
      challengeId,
      recipientCpId,
      locale: recipient.locale,
      timestamp: new Date().toISOString(),
    },
    android: {
      notification: {
        channelId: 'challenge_updates',
        icon: '@mipmap/ic_launcher',
        sound: 'default' as const,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {title, body},
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await getMessaging().send(message);
    logger.info(`Notification sent to ${recipientCpId}: ${response}`);
    return {success: true, messageId: response};
  } catch (error) {
    logger.error(`Failed to send notification to ${recipientCpId}:`, error);
    return {success: false, reason: 'send_failed'};
  }
});

/**
 * Callable function: schedule daily reminders for a challenge
 *
 * Writes a reminder schedule document to Firestore for the daily trigger
 * Accepts: { challengeId }
 */
export const scheduleChallengeReminders = onCall(async (request) => {
  const {challengeId} = request.data;

  if (!challengeId) {
    throw new HttpsError('invalid-argument', 'challengeId is required');
  }

  const db = getFirestore();

  // Verify challenge exists
  const challengeDoc = await db.collection('group_challenges').doc(challengeId).get();
  if (!challengeDoc.exists) {
    throw new HttpsError('not-found', `Challenge ${challengeId} not found`);
  }

  const challengeData = challengeDoc.data()!;

  // Write reminder schedule document
  await db.collection('challenge_reminder_schedules').doc(challengeId).set({
    challengeId,
    groupId: challengeData.groupId,
    challengeName: challengeData.name || '',
    startDate: challengeData.startDate || challengeData.createdAt,
    endDate: challengeData.endDate,
    active: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  logger.info(`Daily reminders scheduled for challenge ${challengeId}`);
  return {success: true, challengeId};
});
