/**
 * Claim Retention Reward
 * Allows users who are about to delete their account to claim a 1-month free Premium
 * as a retention incentive. This is a one-time offer per user.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { grantPromotionalEntitlement } from "../revenuecat/revenuecatHelper";

const db = admin.firestore();
const RETENTION_REWARD_DAYS = 30; // 1 month

/**
 * Check if user has already claimed the retention reward
 */
export const checkRetentionRewardStatus = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;

    try {
      console.log(`🔍 [RETENTION] Checking retention reward status for user ${userId}`);

      // Check if user has already claimed retention reward
      const retentionDoc = await db
        .collection("retentionRewards")
        .doc(userId)
        .get();

      if (retentionDoc.exists) {
        const data = retentionDoc.data()!;
        console.log(`📋 [RETENTION] User ${userId} already claimed retention reward on ${data.claimedAt?.toDate()}`);
        
        return {
          alreadyClaimed: true,
          claimedAt: data.claimedAt?.toDate()?.toISOString() || null,
          expiresAt: data.expiresAt?.toDate()?.toISOString() || null,
        };
      }

      console.log(`✅ [RETENTION] User ${userId} is eligible for retention reward`);
      return {
        alreadyClaimed: false,
        claimedAt: null,
        expiresAt: null,
      };
    } catch (error) {
      console.error(`❌ [RETENTION] Error checking retention status for ${userId}:`, error);
      throw new HttpsError(
        "internal",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);

/**
 * Claim 1-month Premium reward as retention incentive
 * User-facing function that users can call when they're on the delete account screen
 */
export const claimRetentionReward = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;

    try {
      console.log(`🎁 [RETENTION] User ${userId} attempting to claim retention reward`);

      // Check if user has already claimed retention reward
      const retentionDoc = await db
        .collection("retentionRewards")
        .doc(userId)
        .get();

      if (retentionDoc.exists) {
        const data = retentionDoc.data()!;
        const claimedAt = data.claimedAt?.toDate();
        const claimedAtStr = claimedAt
          ? claimedAt.toLocaleDateString()
          : "previously";

        console.log(`⚠️ [RETENTION] User ${userId} already claimed retention reward on ${claimedAtStr}`);

        return {
          success: false,
          message: `You have already claimed your free month on ${claimedAtStr}. This offer is available once per account.`,
          alreadyClaimed: true,
          claimedAt: claimedAtStr,
        };
      }

      // Get user document to verify they exist
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.error(`❌ [RETENTION] User ${userId} not found in database`);
        throw new HttpsError("not-found", "User account not found");
      }

      console.log(`✅ [RETENTION] User ${userId} is eligible for retention reward, granting ${RETENTION_REWARD_DAYS} days`);

      // Grant 30-day Premium reward via RevenueCat
      const rewardResult = await grantPromotionalEntitlement(userId, RETENTION_REWARD_DAYS);

      if (!rewardResult.success) {
        console.error(
          `❌ [RETENTION] Failed to grant retention reward to ${userId}: ${rewardResult.error}`
        );
        throw new HttpsError(
          "internal",
          `Failed to activate your Premium access. Please try again or contact support. Error: ${rewardResult.error}`
        );
      }

      // Create retention reward document to track the claim
      await db.collection("retentionRewards").doc(userId).set({
        userId: userId,
        userEmail: userDoc.data()?.email || "Unknown",
        userName: userDoc.data()?.displayName || "Unknown",
        type: "retention_reward",
        daysGranted: RETENTION_REWARD_DAYS,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: rewardResult.expiresAt,
        revenueCatResponse: {
          expiresAt: rewardResult.expiresAt.toISOString(),
        },
        status: "awarded",
        source: "delete_account_screen",
      });

      console.log(
        `✅ [RETENTION] Successfully granted ${RETENTION_REWARD_DAYS}-day retention reward to ${userId}`
      );

      return {
        success: true,
        message: `Congratulations! You now have ${RETENTION_REWARD_DAYS} days of free Premium access!`,
        daysGranted: RETENTION_REWARD_DAYS,
        expiresAt: rewardResult.expiresAt.toISOString(),
        alreadyClaimed: false,
      };
    } catch (error) {
      console.error(`❌ [RETENTION] Error claiming retention reward for ${userId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);

