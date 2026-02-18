import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { getUserLocale } from './utils/localeHelper';

/**
 * Localization for group member management notifications
 */
const translations = {
  english: {
    'promoted-title': 'Promoted to Admin',
    'promoted-body': 'Congratulations! You have been promoted to admin in {groupName}. You now have administrative privileges.',
    'demoted-title': 'Role Changed',
    'demoted-body': 'You have been demoted to member in {groupName}. Your administrative privileges have been removed.',
    'removed-title': 'Removed from Group',
    'removed-body': 'You have been removed from {groupName}. You can rejoin after 24 hours.',
  },
  arabic: {
    'promoted-title': 'تم ترقيتك إلى مشرف',
    'promoted-body': 'تهانينا! تم ترقيتك إلى مشرف في {groupName}. لديك الآن صلاحيات إدارية.',
    'demoted-title': 'تم تغيير رتبتك',
    'demoted-body': 'تم تخفيض رتبتك إلى عضو في {groupName}. تم إزالة صلاحياتك الإدارية.',
    'removed-title': 'تم إزالتك من المجموعة',
    'removed-body': 'تم إزالتك من {groupName}. يمكنك الانضمام مرة أخرى بعد 24 ساعة.',
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
 * Helper function to get user data including locale
 */
async function getUserData(cpId: string) {
  const db = getFirestore();
  
  try {
    // Get community profile to find userUID
    const profileDoc = await db.collection('communityProfiles').doc(cpId).get();
    if (!profileDoc.exists) {
      logger.warn(`Community profile not found for cpId: ${cpId}`);
      return null;
    }
    
    const profileData = profileDoc.data();
    const userUID = profileData?.userUID;
    
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
      locale: userData?.locale || 'english',
      fcmToken: userData?.messagingToken || userData?.fcmToken, // Support both field names
      displayName: profileData?.displayName || profileData?.firstName || 'User'
    };
  } catch (error) {
    logger.error('Error getting user data:', error);
    return null;
  }
}

/**
 * Helper function to get group data
 */
async function getGroupData(groupId: string) {
  const db = getFirestore();
  
  try {
    const groupDoc = await db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      logger.warn(`Group not found for groupId: ${groupId}`);
      return null;
    }
    
    const groupData = groupDoc.data();
    return {
      name: groupData?.name || 'Group',
      nameAr: groupData?.nameAr || groupData?.name || 'مجموعة'
    };
  } catch (error) {
    logger.error('Error getting group data:', error);
    return null;
  }
}

/**
 * Helper function to send notification
 */
async function sendNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data,
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high' as const,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    await getMessaging().send(message);
    logger.info(`✅ Notification sent successfully to token: ${fcmToken.substring(0, 20)}...`);
  } catch (error) {
    logger.error('Error sending notification:', error);
  }
}

/**
 * Cloud Function to handle member management notifications
 * Triggers on: /group_memberships/{membershipId} document updates
 */
export const sendMemberManagementNotification = onDocumentUpdated(
  'group_memberships/{membershipId}',
  async (event) => {
    try {
      const membershipId = event.params.membershipId;
      logger.info(`🚀 [MEMBER_MGMT_NOTIFICATION] Processing update for membership: ${membershipId}`);

      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!beforeData || !afterData) {
        logger.warn('Missing before or after data');
        return;
      }

      const cpId = afterData.cpId;
      const groupId = afterData.groupId;
      
      if (!cpId || !groupId) {
        logger.warn('Missing cpId or groupId in membership data');
        return;
      }

      // Get user and group data
      const [userData, groupData] = await Promise.all([
        getUserData(cpId),
        getGroupData(groupId)
      ]);

      if (!userData || !groupData) {
        logger.warn('Failed to get user or group data');
        return;
      }

      if (!userData.fcmToken) {
        logger.info(`No FCM token found for user ${userData.userUID} (cpId: ${cpId})`);
        return;
      }

      const locale = getUserLocale(userData);
      const groupName = locale === 'arabic' ? groupData.nameAr : groupData.name;

      // Check for role changes (promotion/demotion)
      if (beforeData.role !== afterData.role) {
        if (beforeData.role === 'member' && afterData.role === 'admin') {
          // Promotion to admin
          const title = translate('promoted-title', locale);
          const body = translate('promoted-body', locale, { groupName });
          
          await sendNotification(userData.fcmToken, title, body, {
            screen: 'groups',
            groupId,
            notificationType: 'member_promoted',
            membershipId
          });
          
          logger.info(`✅ Promotion notification sent to user ${userData.userUID} (cpId: ${cpId}) for group ${groupId}`);
        } else if (beforeData.role === 'admin' && afterData.role === 'member') {
          // Demotion to member
          const title = translate('demoted-title', locale);
          const body = translate('demoted-body', locale, { groupName });
          
          await sendNotification(userData.fcmToken, title, body, {
            screen: 'groups',
            groupId,
            notificationType: 'member_demoted',
            membershipId
          });
          
          logger.info(`✅ Demotion notification sent to user ${userData.userUID} (cpId: ${cpId}) for group ${groupId}`);
        }
      }

      // Check for removal (isActive changed from true to false)
      if (beforeData.isActive === true && afterData.isActive === false) {
        // Member was removed from group
        const title = translate('removed-title', locale);
        const body = translate('removed-body', locale, { groupName });
        
        await sendNotification(userData.fcmToken, title, body, {
          screen: 'groups',
          groupId,
          notificationType: 'member_removed',
          membershipId
        });
        
        logger.info(`✅ Removal notification sent to user ${userData.userUID} (cpId: ${cpId}) for group ${groupId}`);
      }

    } catch (error) {
      logger.error('❌ [MEMBER_MGMT_NOTIFICATION] Error processing member management notification:', error);
    }
  }
);
