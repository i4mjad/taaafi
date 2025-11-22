/**
 * Redeem Referral Code
 * Allows new users to redeem a referral code during signup
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendReferralNotification, getUserDisplayName } from "./notifications/notificationHelper";
import { NotificationType } from "./notifications/notificationTypes";

interface RedeemReferralCodeData {
  code: string;
}

/**
 * Callable function to redeem a referral code
 * Links a new user to their referrer
 */
export const redeemReferralCode = functions.https.onCall(
  async (data: RedeemReferralCodeData, context) => {
    try {
      // 1. Verify user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated to redeem a code"
        );
      }

      const userId = context.auth.uid;
      const code = data.code?.trim().toUpperCase();

      // 2. Validate code format
      if (!code || code.length < 6 || code.length > 8) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid code format"
        );
      }

      console.log(`🔍 Attempting to redeem code: ${code} for user: ${userId}`);

      const db = admin.firestore();

      // 3. Get user document to check if they've already used a code
      const userDoc = await db.collection("users").doc(userId).get();
      const userData = userDoc.data();

      if (!userData) {
        throw new functions.https.HttpsError(
          "not-found",
          "User profile not found"
        );
      }

      if (userData.referredBy) {
        throw new functions.https.HttpsError(
          "already-exists",
          "You have already used a referral code"
        );
      }

      // 3.5. Check if this email was previously used with ANY referral code (fraud prevention)
      // This prevents someone from deleting their account and re-registering with same email
      const userEmail = userData.email || context.auth.token.email;
      
      if (userEmail) {
        const normalizedEmail = userEmail.toLowerCase().trim();
        
        // Check for any previous verifications with this email (including deleted accounts)
        const previousVerifications = await db
          .collection("referralVerifications")
          .where("userEmail", "==", normalizedEmail)
          .limit(1)
          .get();

        if (!previousVerifications.empty) {
          const prevVerification = previousVerifications.docs[0].data();
          const wasDeleted = prevVerification.verificationStatus === 'deleted';
          
          console.warn(
            `⚠️ User ${userId} (${userEmail}) attempted to reuse referral code. ` +
            `Previous verification found${wasDeleted ? ' (deleted account)' : ''}.`
          );
          
          // Log to fraud detection
          await db.collection('referralFraudLogs').add({
            userId: userId,
            action: 'duplicate_email_attempt',
            userEmail: normalizedEmail,
            previousUserId: prevVerification.userId,
            wasDeleted: wasDeleted,
            attemptedCode: code,
            reason: 'Email previously used with referral code',
            performedBy: 'system',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
              previousReferrerId: prevVerification.referrerId,
              previousVerificationStatus: prevVerification.verificationStatus,
            }
          });
          
          throw new functions.https.HttpsError(
            "already-exists",
            wasDeleted
              ? "This email was previously used with a referral code. You cannot reuse referral codes."
              : "This email has already been used with a referral code"
          );
        }
      }

      // 4. Find referral code in database
      const codeQuery = await db
        .collection("referralCodes")
        .where("code", "==", code)
        .where("isActive", "==", true)
        .limit(1)
        .get();

      if (codeQuery.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "Invalid referral code. Please check and try again."
        );
      }

      const codeDoc = codeQuery.docs[0];
      const codeData = codeDoc.data();
      const referrerId = codeData.userId;

      // 5. Check user isn't redeeming their own code
      if (referrerId === userId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "You cannot use your own referral code"
        );
      }

      // 6. Get referrer's user document to verify account is active
      const referrerDoc = await db.collection("users").doc(referrerId).get();
      const referrerData = referrerDoc.data();

      if (!referrerData) {
        throw new functions.https.HttpsError(
          "not-found",
          "Referrer account not found"
        );
      }

      // Optional: Check if referrer account is active/not banned
      if (referrerData.isBanned === true || referrerData.isDeleted === true) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This referral code is no longer valid"
        );
      }

      console.log(`✅ Valid code found, referrer: ${referrerId}`);

      // 7. Create all updates in a batch
      const batch = db.batch();
      const now = admin.firestore.FieldValue.serverTimestamp();

      // Create referralVerifications document
      const verificationRef = db.collection("referralVerifications").doc(userId);
      batch.set(verificationRef, {
        userId,
        referrerId,
        referralCode: code,
        userEmail: (userData.email || context.auth.token.email || '').toLowerCase().trim(), // Track email for duplicate prevention
        signupDate: now,
        currentTier: "none",
        checklist: {
          accountAge7Days: { completed: false, completedAt: null },
          forumPosts3: { completed: false, completedAt: null, current: 0 },
          interactions5: {
            completed: false,
            completedAt: null,
            current: 0,
            uniqueUsers: [],
          },
          groupJoined: {
            completed: false,
            completedAt: null,
            groupId: null,
          },
          groupMessages3: { completed: false, completedAt: null, current: 0 },
          activityStarted: {
            completed: false,
            completedAt: null,
            activityId: null,
          },
        },
        verificationStatus: "pending",
        verifiedAt: null,
        fraudScore: 0,
        fraudFlags: [],
        isBlocked: false,
        blockedReason: null,
        blockedAt: null,
        rewardAwarded: false,
        rewardAwardedAt: null,
        lastCheckedAt: now,
        updatedAt: now,
      });

      // Update referralCode document (increment redemptions)
      const codeRef = db.collection("referralCodes").doc(codeDoc.id);
      batch.update(codeRef, {
        totalRedemptions: admin.firestore.FieldValue.increment(1),
        lastUsedAt: now,
      });

      // Update referrer's stats (increment totalReferred and pendingVerifications)
      const statsRef = db.collection("referralStats").doc(referrerId);
      batch.update(statsRef, {
        totalReferred: admin.firestore.FieldValue.increment(1),
        pendingVerifications: admin.firestore.FieldValue.increment(1),
        lastUpdatedAt: now,
      });

      // Update referee's user document
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        referredBy: referrerId,
        referralSignupDate: now,
      });

      // Commit all changes
      await batch.commit();

      console.log(
        `🎉 Referral code redeemed successfully! User ${userId} referred by ${referrerId}`
      );

      // Send notifications
      try {
        // Get display names
        const refereeName = await getUserDisplayName(userId);
        const referrerName = await getUserDisplayName(referrerId);

        // Notify referrer about new signup
        await sendReferralNotification(
          referrerId,
          NotificationType.FRIEND_SIGNED_UP,
          {
            friendName: refereeName,
          }
        );

        // Welcome notification for referee
        await sendReferralNotification(
          userId,
          NotificationType.WELCOME,
          {
            referrerName: referrerName,
          }
        );

        console.log("✅ Notifications sent successfully");
      } catch (notificationError) {
        // Log but don't fail the function if notifications fail
        console.error("⚠️ Error sending notifications:", notificationError);
      }

      // Return success with referrer info
      return {
        success: true,
        message: "Referral code verified successfully!",
        referrerId,
        referrerName: referrerData.displayName || referrerData.email || "A friend",
      };
    } catch (error) {
      console.error("❌ Error redeeming referral code:", error);

      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Wrap other errors
      throw new functions.https.HttpsError(
        "internal",
        `Failed to redeem code: ${error}`
      );
    }
  }
);
