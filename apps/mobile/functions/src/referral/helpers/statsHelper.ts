/**
 * Referral Stats Helper
 * Initialize and manage referral statistics
 */

import * as admin from "firebase-admin";

/**
 * Initialize referral stats document for a new user
 * @param userId - User's UID
 */
export async function initializeReferralStats(userId: string): Promise<void> {
  const db = admin.firestore();

  await db
    .collection("referralStats")
    .doc(userId)
    .set({
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

  console.log(`✅ Initialized referral stats for user: ${userId}`);
}
