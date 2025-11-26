/**
 * Manual Reward Grant Function
 * Admin-only function to manually grant rewards to users who didn't receive them
 * Use case: Retroactively grant rewards to users verified before reward system was working
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { grantPromotionalEntitlement } from "../revenuecat/revenuecatHelper";

const db = admin.firestore();

/**
 * Manually grant 30-day reward to verified referee
 * ADMIN ONLY - Requires authentication
 */
export const manuallyGrantRefereeReward = functions.https.onCall(
  async (data: { userId: string }, context) => {
    // Verify admin authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    // TODO: Add admin check
    // For now, any authenticated user can call this
    // In production, verify: context.auth.token.admin === true

    const { userId } = data;

    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required"
      );
    }

    try {
      console.log(`🔧 Manual reward grant requested for user: ${userId}`);

      // Get verification document
      const verificationDoc = await db
        .collection("referralVerifications")
        .doc(userId)
        .get();

      if (!verificationDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User has no referral verification"
        );
      }

      const verification = verificationDoc.data()!;

      // Check if already awarded
      if (verification.rewardAwarded) {
        return {
          success: false,
          message: "Reward already granted to this user",
          alreadyGranted: true,
        };
      }

      // Check if verified
      if (verification.verificationStatus !== "verified") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `User verification status is ${verification.verificationStatus}, must be 'verified'`
        );
      }

      console.log(`✅ User ${userId} is eligible for manual reward grant`);

      // Grant 30-day Premium reward (1 month)
      const rewardResult = await grantPromotionalEntitlement(userId, 30);

      if (!rewardResult.success) {
        throw new functions.https.HttpsError(
          "internal",
          `Failed to grant reward: ${rewardResult.error}`
        );
      }

      // Log reward in referralRewards collection
      await db.collection("referralRewards").add({
        referrerId: userId,
        type: "referee_reward_manual",
        amount: "1 month",
        daysGranted: 30,
        verifiedUserIds: [userId],
        revenueCatResponse: {
          expiresAt: rewardResult.expiresAt.toISOString(),
        },
        awardedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: rewardResult.expiresAt,
        status: "awarded",
        grantedBy: context.auth.uid,
        reason: "Manual grant - reward not awarded during verification",
      });

      // Update verification document
      await db
        .collection("referralVerifications")
        .doc(userId)
        .update({
          rewardAwarded: true,
          rewardAwardedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ Successfully granted 30-day reward to ${userId} manually`);

      return {
        success: true,
        message: "Reward granted successfully",
        daysGranted: 30,
        expiresAt: rewardResult.expiresAt.toISOString(),
      };
    } catch (error) {
      console.error(`❌ Error granting manual reward to ${userId}:`, error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);
