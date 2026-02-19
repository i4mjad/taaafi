/**
 * Referral Reward Types
 */

export interface RewardCalculation {
  totalVerified: number;
  totalPaidConversions: number;
  blockedReferrals: number;
  adjustedVerified: number; // After removing blocked
  monthsEarned: number;
  weeksEarned: number;
  totalDays: number;
  hasUnredeemedRewards: boolean;
  lastRedemptionAt: Date | null;
}

export interface RedemptionResult {
  success: boolean;
  daysGranted: number;
  expiresAt: Date;
  message?: string;
  error?: string;
}

export interface ReferralReward {
  referrerId: string;
  type: "verification_milestone" | "paid_conversion" | "referee_reward";
  amount: string; // e.g., "1 month", "2 weeks", "3 days"
  daysGranted: number;
  verifiedUserIds: string[]; // Users who contributed to this reward
  revenueCatResponse?: object;
  awardedAt: FirebaseFirestore.FieldValue;
  expiresAt: Date;
  status: "awarded" | "expired" | "revoked";
  revocationReason?: string;
}

