/**
 * Notification templates for referral program
 * Supports English and Arabic localization
 */

import { NotificationType } from './notificationTypes';

interface NotificationTemplate {
  title: string;
  body: string;
}

interface NotificationTemplates {
  en: Record<NotificationType, NotificationTemplate>;
  ar: Record<NotificationType, NotificationTemplate>;
}

export const notificationTemplates: NotificationTemplates = {
  en: {
    [NotificationType.FRIEND_SIGNED_UP]: {
      title: '🎉 New Referral!',
      body: '{friendName} signed up with your code!'
    },
    [NotificationType.FRIEND_TASK_PROGRESS]: {
      title: '✅ Friend Made Progress',
      body: '{friendName} completed: {taskName}'
    },
    [NotificationType.FRIEND_VERIFIED]: {
      title: '✅ Friend Verified!',
      body: '{friendName} completed verification. Progress: {progress} verified!'
    },
    [NotificationType.FRIEND_SUBSCRIBED]: {
      title: '💰 Bonus Earned!',
      body: '{friendName} subscribed to Premium. You earned 2 weeks bonus!'
    },
    [NotificationType.FRIEND_DELETED]: {
      title: '📊 Referral Update',
      body: 'One of your referrals deleted their account. Your stats have been updated.'
    },
    [NotificationType.MILESTONE_REACHED]: {
      title: '🎁 Reward Unlocked!',
      body: 'You earned {reward}! Tap to redeem.'
    },
    [NotificationType.REWARD_READY]: {
      title: '🎁 Reward Ready!',
      body: 'Your {reward} is ready. Tap to claim it now!'
    },
    [NotificationType.REWARD_REDEEMED]: {
      title: '🎉 Rewards Redeemed!',
      body: 'You got {duration} of Premium access! Expires: {expiresAt}'
    },
    [NotificationType.WELCOME]: {
      title: '🌟 Welcome to Ta3afi!',
      body: 'Thanks for using {referrerName}\'s code! Complete tasks to unlock Premium.'
    },
    [NotificationType.TASK_COMPLETED]: {
      title: '✅ Task Completed!',
      body: '{taskName} done! Progress: {progress}'
    },
    [NotificationType.PROGRESS_UPDATE]: {
      title: '📊 Keep Going!',
      body: 'You\'ve completed {progress} tasks. Keep it up!'
    },
    [NotificationType.VERIFICATION_COMPLETE]: {
      title: '🎉 You\'re Verified!',
      body: 'Congrats! You earned 3 days of Premium access. Explore now!'
    },
    [NotificationType.PREMIUM_ACTIVATED]: {
      title: '💎 Premium Activated!',
      body: 'Your Premium access is now active. Enjoy all features!'
    }
  },
  ar: {
    [NotificationType.FRIEND_SIGNED_UP]: {
      title: '🎉 إحالة جديدة!',
      body: '{friendName} سجل باستخدام كودك!'
    },
    [NotificationType.FRIEND_TASK_PROGRESS]: {
      title: '✅ صديقك أحرز تقدماً',
      body: '{friendName} أكمل: {taskName}'
    },
    [NotificationType.FRIEND_VERIFIED]: {
      title: '✅ تم التحقق من صديقك!',
      body: '{friendName} أكمل التحقق. التقدم: {progress} تم التحقق منهم!'
    },
    [NotificationType.FRIEND_SUBSCRIBED]: {
      title: '💰 حصلت على مكافأة!',
      body: '{friendName} اشترك في البريميوم. حصلت على أسبوعين إضافيين!'
    },
    [NotificationType.FRIEND_DELETED]: {
      title: '📊 تحديث في برنامج الإحالة',
      body: 'أحد المستخدمين الذين تمت إحالتهم قد حذف حسابه. تم تحديث إحصائياتك.'
    },
    [NotificationType.MILESTONE_REACHED]: {
      title: '🎁 فتحت مكافأة!',
      body: 'حصلت على {reward}! اضغط للمطالبة بها.'
    },
    [NotificationType.REWARD_READY]: {
      title: '🎁 مكافأتك جاهزة!',
      body: '{reward} الخاص بك جاهز. اضغط للمطالبة به الآن!'
    },
    [NotificationType.WELCOME]: {
      title: '🌟 مرحباً بك في تعافي!',
      body: 'شكراً لاستخدام كود {referrerName}! أكمل المهام لفتح البريميوم.'
    },
    [NotificationType.TASK_COMPLETED]: {
      title: '✅ تم إنجاز المهمة!',
      body: '{taskName} تم! التقدم: {progress}'
    },
    [NotificationType.PROGRESS_UPDATE]: {
      title: '📊 استمر!',
      body: 'أكملت {progress} من المهام. واصل التقدم!'
    },
    [NotificationType.VERIFICATION_COMPLETE]: {
      title: '🎉 تم التحقق منك!',
      body: 'تهانينا! حصلت على 3 أيام بريميوم. استكشف الآن!'
    },
    [NotificationType.PREMIUM_ACTIVATED]: {
      title: '💎 تم تفعيل البريميوم!',
      body: 'وصولك للبريميوم نشط الآن. استمتع بجميع المميزات!'
    },
    [NotificationType.REWARD_REDEEMED]: {
      title: '🎉 تم استرداد المكافآت!',
      body: 'حصلت على {duration} وصول بريميوم! تنتهي في: {expiresAt}'
    }
  }
};

/**
 * Build a notification from a template with dynamic data
 */
export function buildNotification(
  type: NotificationType,
  locale: string,
  data: Record<string, string>
): { title: string; body: string } {
  // Normalize locale
  const normalizedLocale = locale.toLowerCase().includes('ar') ? 'ar' : 'en';
  
  const template = notificationTemplates[normalizedLocale][type];
  
  if (!template) {
    console.error(`Unknown notification type: ${type}`);
    return {
      title: 'Notification',
      body: 'You have a new notification'
    };
  }
  
  // Replace placeholders in title and body
  let title = template.title;
  let body = template.body;
  
  Object.entries(data).forEach(([key, value]) => {
    const placeholder = `{${key}}`;
    title = title.replace(placeholder, value);
    body = body.replace(placeholder, value);
  });
  
  return { title, body };
}

