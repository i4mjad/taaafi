/**
 * Generate Referral Code on User Creation
 * Automatically creates referral code when a new user signs up
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { generateAndEnsureUniqueCode } from "./helpers/codeGenerator";
import { initializeReferralStats } from "./helpers/statsHelper";

/**
 * Trigger: Runs when a new Firebase Auth user is created
 * Creates referral code, stats, and updates user document
 */
export const generateReferralCodeOnUserCreation = functions.auth
  .user()
  .onCreate(async (user) => {
    try {
      const userId = user.uid;
      const displayName = user.displayName || "";
      const email = user.email || "";

      console.log(
        `🔥 New user created: ${userId} (${displayName || email})`
      );

      // Generate unique referral code
      const code = await generateAndEnsureUniqueCode(displayName, email);

      const db = admin.firestore();
      const batch = db.batch();

      // 1. Create referralCodes document
      const referralCodeRef = db.collection("referralCodes").doc();
      batch.set(referralCodeRef, {
        userId,
        code,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        totalRedemptions: 0,
        lastUsedAt: null,
      });

      console.log(`✅ Referral code created: ${code} for user: ${userId}`);

      // 2. Create referralStats document
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

      // 3. Update user document with referral code
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        referralCode: code,
      });

      // Execute all writes atomically
      await batch.commit();

      console.log(
        `🎉 Referral system initialized for user: ${userId} with code: ${code}`
      );

      return { success: true, code };
    } catch (error) {
      console.error(`❌ Error generating referral code:`, error);

      // Don't throw - we don't want user creation to fail if referral code generation fails
      // The backfill function can handle this later
      return { success: false, error: String(error) };
    }
  });
