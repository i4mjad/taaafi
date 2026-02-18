/**
 * Redeem Referral Rewards
 * Callable Cloud Function for users to redeem their earned rewards
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  calculateUserRewards,
  isEligibleForRewards,
  getRewardBreakdown,
} from "./rewardCalculator";
import { grantPromotionalEntitlement } from "../revenuecat/revenuecatHelper";
import { sendReferralNotification } from "../notifications/notificationHelper";
import { NotificationType } from "../notifications/notificationTypes";

const db = admin.firestore();

/**
 * Redeem Referral Rewards
 * Callable function for users to redeem their accumulated rewards
 * Note: API key loaded from .env file automatically
 */
export const redeemReferralRewards = functions.https.onCall(
  async (data, context) => {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;

    try {
      console.log(`User ${userId} attempting to redeem rewards`);

      // Check eligibility
      const eligibility = await isEligibleForRewards(userId);
      if (!eligibility.eligible) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          eligibility.reason || "Not eligible for rewards"
        );
      }

      // Get reward breakdown
      const breakdown = await getRewardBreakdown(userId);

      if (breakdown.pendingRedemption <= 0) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No pending rewards to redeem"
        );
      }

      console.log(
        `Redeeming ${breakdown.pendingRedemption} days for ${userId}`
      );

      // Grant promotional entitlement via RevenueCat
      const result = await grantPromotionalEntitlement(
        userId,
        breakdown.pendingRedemption
      );

      if (!result.success) {
        throw new functions.https.HttpsError(
          "internal",
          result.error || "Failed to grant rewards"
        );
      }

      // Log reward redemption in referralRewards collection
      const rewardDoc = await db.collection("referralRewards").add({
        referrerId: userId,
        type: "verification_milestone",
        amount: formatRewardAmount(breakdown),
        daysGranted: breakdown.pendingRedemption,
        verifiedUserIds: [], // Could track specific users
        revenueCatResponse: {
          expiresAt: result.expiresAt.toISOString(),
        },
        awardedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: result.expiresAt,
        status: "awarded",
      });

      console.log(
        `Reward redemption logged: ${rewardDoc.id}`
      );

      // Update referralStats with redemption timestamp
      await db
        .collection("referralStats")
        .doc(userId)
        .update({
          "rewardsEarned.lastRedemptionAt":
            admin.firestore.FieldValue.serverTimestamp(),
          "rewardsEarned.totalDaysGranted":
            admin.firestore.FieldValue.increment(
              breakdown.pendingRedemption
            ),
        });

      // Send success notification
      await sendReferralNotification(
        userId,
        NotificationType.REWARD_REDEEMED,
        {
          duration: `${breakdown.pendingRedemption} days`,
          expiresAt: result.expiresAt.toISOString(),
        }
      );

      console.log(
        `Successfully redeemed ${breakdown.pendingRedemption} days for ${userId}`
      );

      return {
        success: true,
        daysGranted: breakdown.pendingRedemption,
        expiresAt: result.expiresAt.toISOString(),
        breakdown: {
          verificationDays: breakdown.verificationRewards,
          paidConversionDays: breakdown.paidConversionRewards,
        },
      };
    } catch (error) {
      console.error(`Error redeeming rewards for ${userId}:`, error);

      // If it's already an HttpsError, rethrow it
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Otherwise, wrap in internal error
      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);

/**
 * Format reward amount for display
 */
function formatRewardAmount(breakdown: {
  verificationRewards: number;
  paidConversionRewards: number;
}): string {
  const parts: string[] = [];

  if (breakdown.verificationRewards > 0) {
    const months = Math.floor(breakdown.verificationRewards / 30);
    if (months > 0) {
      parts.push(`${months} month${months > 1 ? "s" : ""}`);
    }
  }

  if (breakdown.paidConversionRewards > 0) {
    const weeks = Math.floor(breakdown.paidConversionRewards / 7);
    if (weeks > 0) {
      parts.push(`${weeks} week${weeks > 1 ? "s" : ""}`);
    }
  }

  return parts.join(" + ") || "0 days";
}

