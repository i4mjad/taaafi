/**
 * Notification types for referral program
 */

export enum NotificationType {
  // For Referrer
  FRIEND_SIGNED_UP = 'friend_signed_up',
  FRIEND_TASK_PROGRESS = 'friend_task_progress',
  FRIEND_VERIFIED = 'friend_verified',
  FRIEND_SUBSCRIBED = 'friend_subscribed',
  MILESTONE_REACHED = 'milestone_reached',
  REWARD_READY = 'reward_ready',
  
  // For Referee
  WELCOME = 'welcome',
  TASK_COMPLETED = 'task_completed',
  PROGRESS_UPDATE = 'progress_update',
  VERIFICATION_COMPLETE = 'verification_complete',
  PREMIUM_ACTIVATED = 'premium_activated',
}

export interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}

export interface ReferralNotificationData {
  friendName?: string;
  referrerName?: string;
  taskName?: string;
  progress?: string;
  reward?: string;
  verifiedCount?: number;
  referralCode?: string;
}

