// functions/src/referral/types/referral.types.ts

/**
 * Types for the referral verification system.
 * These definitions are used across helper modules and Cloud Functions.
 */
export interface ChecklistItem {
  completed: boolean;
  completedAt: FirebaseFirestore.Timestamp | null;
  current?: number;
  groupId?: string;
  activityId?: string;
  uniqueUsers?: string[];
  categories?: string[];
}

export interface ReferralVerification {
  userId: string;
  referrerId: string;
  referralCode: string;
  signupDate: FirebaseFirestore.Timestamp;
  currentTier: 'none' | 'verified' | 'paid';
  checklist: {
    accountAge7Days: ChecklistItem;
    forumPosts3: ChecklistItem;
    interactions5: ChecklistItem;
    groupJoined: ChecklistItem;
    groupMessages3: ChecklistItem;
    activityStarted: ChecklistItem;
  };
  verificationStatus: 'pending' | 'verified' | 'blocked';
  verifiedAt: FirebaseFirestore.Timestamp | null;
  fraudScore: number;
  fraudFlags: string[];
  isBlocked: boolean;
  blockedReason: string | null;
  blockedAt: FirebaseFirestore.Timestamp | null;
  rewardAwarded: boolean;
  rewardAwardedAt: FirebaseFirestore.Timestamp | null;
  lastCheckedAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface VerificationRequirements {
  minAccountAgeDays: number;
  minForumPosts: number;
  minInteractions: number;
  minGroupMessages: number;
  minActivitiesStarted: number;
}

export interface FraudThresholds {
  lowRisk: number;
  highRisk: number;
  autoBlock: number;
}

export interface FraudCheckResult {
  checkName: string;
  score: number;
  flag: string | null;
  details?: any;
}

export interface FraudScoreResult {
  totalScore: number;
  flags: string[];
  checks: FraudCheckResult[];
}

export interface FraudLog {
  userId: string;
  action: 'auto_block' | 'flagged' | 'manual_block' | 'approved';
  fraudScore: number;
  fraudFlags: string[];
  reason: string;
  performedBy: string; // 'system' or admin UID
  timestamp: FirebaseFirestore.Timestamp;
  details: object;
}
