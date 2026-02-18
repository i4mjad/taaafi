/**
 * Claim Referee Reward
 * Allows verified referees to manually claim their 30-day Premium reward
 * if it wasn't auto-granted during verification
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { grantPromotionalEntitlement } from "../revenuecat/revenuecatHelper";
import { sendReferralNotification } from "../notifications/notificationHelper";
import { NotificationType } from "../notifications/notificationTypes";

const db = admin.firestore();

/**
 * Claim 30-day Premium reward for verified referee
 * User-facing function that verified users can call themselves
 */
export const claimRefereeReward = functions.https.onCall(
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
      console.log(`🎁 User ${userId} attempting to claim referee reward`);

      // Get verification document
      const verificationDoc = await db
        .collection("referralVerifications")
        .doc(userId)
        .get();

      if (!verificationDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "You were not referred by anyone. This reward is only for users who signed up with a referral code."
        );
      }

      const verification = verificationDoc.data()!;

      // Check if already awarded
      if (verification.rewardAwarded) {
        // Check when it was awarded
        const awardedAt = verification.rewardAwardedAt?.toDate();
        const awardedAtStr = awardedAt
          ? awardedAt.toLocaleDateString()
          : "previously";

        return {
          success: false,
          message: `You already claimed your 1-month Premium reward on ${awardedAtStr}!`,
          alreadyClaimed: true,
          awardedAt: awardedAtStr,
        };
      }

      // Check if verified
      if (verification.verificationStatus !== "verified") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `You need to complete all verification tasks first. Current status: ${verification.verificationStatus}`
        );
      }

      // Check if blocked
      if (verification.isBlocked) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Your account is under review. Please contact support."
        );
      }

      console.log(`✅ User ${userId} is eligible to claim reward`);

      // Grant 30-day Premium reward via RevenueCat
      const rewardResult = await grantPromotionalEntitlement(userId, 30);

      if (!rewardResult.success) {
        console.error(
          `❌ Failed to grant reward to ${userId}: ${rewardResult.error}`
        );
        throw new functions.https.HttpsError(
          "internal",
          `Failed to activate your Premium access. Please try again or contact support. Error: ${rewardResult.error}`
        );
      }

      // Log reward in referralRewards collection
      await db.collection("referralRewards").add({
        referrerId: userId,
        type: "referee_reward",
        amount: "1 month",
        daysGranted: 30,
        verifiedUserIds: [userId],
        revenueCatResponse: {
          expiresAt: rewardResult.expiresAt.toISOString(),
        },
        awardedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: rewardResult.expiresAt,
        status: "awarded",
        claimedManually: true, // Flag to track manual claims vs auto-grants
      });

      // Update verification document
      await db
        .collection("referralVerifications")
        .doc(userId)
        .update({
          rewardAwarded: true,
          rewardAwardedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(
        `✅ Successfully granted 30-day reward to ${userId} via manual claim`
      );

      // Send success notification
      try {
        await sendReferralNotification(
          userId,
          NotificationType.VERIFICATION_COMPLETE,
          {}
        );
      } catch (notifError) {
        console.error("⚠️ Error sending notification:", notifError);
        // Don't fail the claim if notification fails
      }

      return {
        success: true,
        message: "Congratulations! You now have 1 month of Premium access!",
        daysGranted: 30,
        expiresAt: rewardResult.expiresAt.toISOString(),
        activatedNow: true,
      };
    } catch (error) {
      console.error(`❌ Error claiming reward for ${userId}:`, error);

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
