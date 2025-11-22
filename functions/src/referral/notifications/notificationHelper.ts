/**
 * Notification helper for referral program
 * Handles sending push notifications and logging
 */

import * as admin from 'firebase-admin';
import { NotificationType, ReferralNotificationData } from './notificationTypes';
import { buildNotification } from './notificationTemplates';
import { getUserLocale, getLanguageCode } from '../../utils/localeHelper';

/**
 * Send a referral notification to a user
 */
export async function sendReferralNotification(
  userId: string,
  type: NotificationType,
  data: ReferralNotificationData
): Promise<boolean> {
  try {
    console.log(`📱 Sending referral notification to ${userId}, type: ${type}`);
    
    // Get user document to retrieve FCM token and locale
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`⚠️ User ${userId} not found`);
      return false;
    }
    
    const userData = userDoc.data();
    
    if (!userData) {
      console.log(`⚠️ User data is empty for ${userId}`);
      return false;
    }
    
    // Check if user has FCM token
    if (!userData.messagingToken) {
      console.log(`⚠️ No FCM token found for user ${userId}`);
      // Still log the notification attempt
      await logNotification(userId, type, 'No FCM token', 'failed');
      return false;
    }
    
    // Get user's locale using standardized helper
    const locale = getUserLocale(userData);
    const languageCode = getLanguageCode(locale);
    
    // Build notification from template
    const notification = buildNotification(type, languageCode, data as Record<string, string>);
    
    // Prepare notification data
    const notificationData: Record<string, string> = {
      type: type,
      notificationType: 'referral',
      userId: userId,
      timestamp: new Date().toISOString(),
      ...Object.entries(data).reduce((acc, [key, value]) => {
        if (value !== undefined && value !== null) {
          acc[key] = String(value);
        }
        return acc;
      }, {} as Record<string, string>)
    };
    
    // Send FCM notification
    const message: admin.messaging.Message = {
      token: userData.messagingToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notificationData,
      android: {
        notification: {
          channelId: 'high_importance_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default',
          priority: 'high' as const,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    const response = await admin.messaging().send(message);
    console.log(`✅ Notification sent successfully: ${response}`);
    
    // Log successful notification
    await logNotification(userId, type, notification.body, 'sent');
    
    return true;
  } catch (error: any) {
    console.error(`❌ Error sending referral notification:`, error);
    
    // Log failed notification
    await logNotification(userId, type, error.message, 'failed');
    
    return false;
  }
}

/**
 * Log notification to Firestore for tracking and debugging
 */
async function logNotification(
  userId: string,
  type: NotificationType,
  message: string,
  status: 'sent' | 'failed' | 'delivered' | 'opened'
): Promise<void> {
  try {
    await admin.firestore().collection('notificationLogs').add({
      userId,
      type,
      category: 'referral',
      message,
      status,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Error logging notification:', error);
    // Don't throw - logging failures shouldn't break notification flow
  }
}

/**
 * Get user's display name for notifications
 */
export async function getUserDisplayName(userId: string): Promise<string> {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData) {
      return 'A friend';
    }
    
    return userData.displayName || userData.name || userData.email?.split('@')[0] || 'A friend';
  } catch (error) {
    console.error(`Error getting user name for ${userId}:`, error);
    return 'A friend';
  }
}

/**
 * Notify referrer about referee's progress
 */
export async function notifyReferrerAboutProgress(
  referrerId: string,
  refereeId: string,
  taskName: string
): Promise<void> {
  try {
    const refereeName = await getUserDisplayName(refereeId);
    
    await sendReferralNotification(
      referrerId,
      NotificationType.FRIEND_TASK_PROGRESS,
      {
        friendName: refereeName,
        taskName: taskName,
      }
    );
  } catch (error) {
    console.error('Error notifying referrer about progress:', error);
  }
}

/**
 * Notify referee about task completion
 */
export async function notifyRefereeAboutTaskCompletion(
  refereeId: string,
  taskName: string,
  completedCount: number,
  totalCount: number
): Promise<void> {
  try {
    await sendReferralNotification(
      refereeId,
      NotificationType.TASK_COMPLETED,
      {
        taskName: taskName,
        progress: `${completedCount}/${totalCount}`,
      }
    );
  } catch (error) {
    console.error('Error notifying referee about task:', error);
  }
}

