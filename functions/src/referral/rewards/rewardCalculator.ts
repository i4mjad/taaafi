/**
 * Reward Calculator
 * Calculate rewards earned by referrers based on verified referrals and paid conversions
 */

import * as admin from "firebase-admin";
import { RewardCalculation } from "./rewardTypes";

const db = admin.firestore();

/**
 * Calculate rewards for a user
 * Formula:
 * - Every 5 verified referrals = 1 month Premium (30 days)
 * - Every paid conversion = 2 weeks Premium (14 days)
 * - Blocked referrals are subtracted from verified count
 */
export async function calculateUserRewards(
  userId: string
): Promise<RewardCalculation> {
  console.log(`Calculating rewards for user ${userId}`);

  // Get user's referral stats
  const statsDoc = await db
    .collection("referralStats")
    .doc(userId)
    .get();

  if (!statsDoc.exists) {
    console.log(`No referral stats found for ${userId}`);
    return {
      totalVerified: 0,
      totalPaidConversions: 0,
      blockedReferrals: 0,
      adjustedVerified: 0,
      monthsEarned: 0,
      weeksEarned: 0,
      totalDays: 0,
      hasUnredeemedRewards: false,
      lastRedemptionAt: null,
    };
  }

  const stats = statsDoc.data()!;

  const totalVerified = stats.totalVerified || 0;
  const totalPaidConversions = stats.totalPaidConversions || 0;
  const blockedReferrals = stats.blockedReferrals || 0;

  // Adjust verified count by removing blocked referrals
  const adjustedVerified = Math.max(0, totalVerified - blockedReferrals);

  // Calculate rewards
  const monthsEarned = Math.floor(adjustedVerified / 5);
  const weeksEarned = totalPaidConversions * 2;
  const totalDays = monthsEarned * 30 + weeksEarned * 7;

  // Check if user has already redeemed
  const lastRedemptionAt = stats.rewardsEarned?.lastRedemptionAt
    ? stats.rewardsEarned.lastRedemptionAt.toDate()
    : null;

  // Check if there are new rewards since last redemption
  const hasUnredeemedRewards = await hasNewRewardsSinceRedemption(
    userId,
    lastRedemptionAt,
    totalDays
  );

  const calculation: RewardCalculation = {
    totalVerified,
    totalPaidConversions,
    blockedReferrals,
    adjustedVerified,
    monthsEarned,
    weeksEarned,
    totalDays,
    hasUnredeemedRewards,
    lastRedemptionAt,
  };

  console.log(`Reward calculation for ${userId}:`, calculation);

  return calculation;
}

/**
 * Check if user has new rewards since last redemption
 */
async function hasNewRewardsSinceRedemption(
  userId: string,
  lastRedemptionAt: Date | null,
  currentTotalDays: number
): Promise<boolean> {
  // If never redeemed and has rewards, return true
  if (!lastRedemptionAt && currentTotalDays > 0) {
    return true;
  }

  // If never redeemed and no rewards, return false
  if (!lastRedemptionAt && currentTotalDays === 0) {
    return false;
  }

  // Query referral rewards to get total days already granted
  const rewardsSnapshot = await db
    .collection("referralRewards")
    .where("referrerId", "==", userId)
    .where("type", "in", ["verification_milestone", "paid_conversion"])
    .where("status", "==", "awarded")
    .get();

  const totalDaysGranted = rewardsSnapshot.docs.reduce((sum, doc) => {
    return sum + (doc.data().daysGranted || 0);
  }, 0);

  // Has unredeemed rewards if current total exceeds what's been granted
  return currentTotalDays > totalDaysGranted;
}

/**
 * Get detailed breakdown of rewards
 */
export async function getRewardBreakdown(userId: string): Promise<{
  verificationRewards: number; // Days from verification milestones
  paidConversionRewards: number; // Days from paid conversions
  totalAwarded: number; // Total days already granted via RevenueCat
  pendingRedemption: number; // Days available to redeem
}> {
  const calculation = await calculateUserRewards(userId);

  const verificationRewards = calculation.monthsEarned * 30;
  const paidConversionRewards = calculation.weeksEarned * 7;

  // Get total already awarded
  const rewardsSnapshot = await db
    .collection("referralRewards")
    .where("referrerId", "==", userId)
    .where("type", "in", ["verification_milestone", "paid_conversion"])
    .where("status", "==", "awarded")
    .get();

  const totalAwarded = rewardsSnapshot.docs.reduce((sum, doc) => {
    return sum + (doc.data().daysGranted || 0);
  }, 0);

  const pendingRedemption = Math.max(
    0,
    calculation.totalDays - totalAwarded
  );

  return {
    verificationRewards,
    paidConversionRewards,
    totalAwarded,
    pendingRedemption,
  };
}

/**
 * Check if user is eligible for rewards
 */
export async function isEligibleForRewards(
  userId: string
): Promise<{ eligible: boolean; reason?: string }> {
  const calculation = await calculateUserRewards(userId);

  // Check if has rewards to redeem
  if (calculation.totalDays === 0) {
    return {
      eligible: false,
      reason: "No rewards earned yet",
    };
  }

  if (!calculation.hasUnredeemedRewards) {
    return {
      eligible: false,
      reason: "All rewards have been redeemed",
    };
  }

  // Check for recent fraud flags
  const recentFraudFlags = await checkRecentFraudFlags(userId);
  if (recentFraudFlags) {
    return {
      eligible: false,
      reason: "Rewards temporarily suspended due to fraud review",
    };
  }

  return { eligible: true };
}

/**
 * Check for recent fraud flags
 */
async function checkRecentFraudFlags(
  userId: string
): Promise<boolean> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const fraudSnapshot = await db
    .collection("referralFraudDetection")
    .where("referrerId", "==", userId)
    .where("status", "==", "flagged")
    .where("createdAt", ">", thirtyDaysAgo)
    .limit(1)
    .get();

  return !fraudSnapshot.empty;
}

