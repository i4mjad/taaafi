/**
 * Backfill Referral Codes for Existing Users
 * One-time callable function to generate codes for users created before this feature
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { generateAndEnsureUniqueCode } from "./helpers/codeGenerator";

/**
 * Callable function to backfill existing users with referral codes
 * Admin only - processes users in batches
 */
export const backfillReferralCodes = functions.https.onCall(
  async (data, context) => {
    try {
      // Check authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      // Check admin permission
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();

      const userData = userDoc.data();
      if (!userData || userData.role !== "admin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins can run backfill"
        );
      }

      console.log(`🔧 Starting referral code backfill by admin: ${context.auth.uid}`);

      const db = admin.firestore();

      // Get all users without referralCode field
      const usersSnapshot = await db
        .collection("users")
        .where("referralCode", "==", null)
        .limit(500) // Process in batches
        .get();

      if (usersSnapshot.empty) {
        console.log("✅ No users found without referral codes");
        return {
          success: true,
          message: "All users already have referral codes",
          count: 0,
        };
      }

      let successCount = 0;
      let errorCount = 0;
      const errors: Array<{ userId: string; error: string }> = [];

      // Process each user
      for (const userDocSnap of usersSnapshot.docs) {
        try {
          const userId = userDocSnap.id;
          const userData = userDocSnap.data();

          // Check if they already have a referral code in referralCodes collection
          const existingCodeQuery = await db
            .collection("referralCodes")
            .where("userId", "==", userId)
            .where("isActive", "==", true)
            .limit(1)
            .get();

          if (!existingCodeQuery.empty) {
            // User already has a code, just update their user document
            const existingCode = existingCodeQuery.docs[0].data().code;
            await db.collection("users").doc(userId).update({
              referralCode: existingCode,
            });
            console.log(`✅ Updated user ${userId} with existing code: ${existingCode}`);
            successCount++;
            continue;
          }

          // Generate new code
          const displayName = userData.displayName || "";
          const email = userData.email || "";
          const code = await generateAndEnsureUniqueCode(displayName, email);

          const batch = db.batch();

          // Create referralCodes document
          const referralCodeRef = db.collection("referralCodes").doc();
          batch.set(referralCodeRef, {
            userId,
            code,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isActive: true,
            totalRedemptions: 0,
            lastUsedAt: null,
          });

          // Create referralStats if it doesn't exist
          const statsDoc = await db.collection("referralStats").doc(userId).get();
          if (!statsDoc.exists) {
            const statsRef = db.collection("referralStats").doc(userId);
            batch.set(statsRef, {
              userId,
              totalReferred: 0,
              totalVerified: 0,
              totalPaidConversions: 0,
              pendingVerifications: 0,
              blockedReferrals: 0,
              rewardsEarned: {
                totalMonths: 0,
                totalWeeks: 0,
                lastRewardAt: null,
              },
              milestones: [],
              lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          // Update user document
          const userRef = db.collection("users").doc(userId);
          batch.update(userRef, {
            referralCode: code,
          });

          await batch.commit();

          console.log(`✅ Backfilled user ${userId} with code: ${code}`);
          successCount++;
        } catch (error) {
          console.error(`❌ Error backfilling user ${userDocSnap.id}:`, error);
          errorCount++;
          errors.push({
            userId: userDocSnap.id,
            error: String(error),
          });
        }
      }

      const result = {
        success: true,
        message: `Backfill complete: ${successCount} successful, ${errorCount} errors`,
        successCount,
        errorCount,
        errors: errors.length > 0 ? errors : undefined,
      };

      console.log(`🎉 Backfill complete:`, result);

      return result;
    } catch (error) {
      console.error("❌ Error in backfill function:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Backfill failed: ${error}`
      );
    }
  }
);
