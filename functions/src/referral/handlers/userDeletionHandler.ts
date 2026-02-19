/**
 * Referral User Deletion Handler
 * 
 * Handles referral-related cleanup when a user deletes their account.
 * This includes notifying referrers and updating stats.
 */

import * as admin from 'firebase-admin';
import { sendReferralNotification } from '../notifications/notificationHelper';
import { NotificationType } from '../notifications/notificationTypes';

const db = admin.firestore();

/**
 * Handle referral cleanup when a user deletes their account
 * This is called from the main deleteUserAccount function
 */
export async function handleReferralUserDeletion(
  userId: string
): Promise<{
  success: boolean;
  referrerNotified: boolean;
  statsUpdated: boolean;
  verificationsMarked: number;
  errors: string[];
}> {
  const result = {
    success: false,
    referrerNotified: false,
    statsUpdated: false,
    verificationsMarked: 0,
    errors: [] as string[]
  };

  try {
    console.log(`🔗 Processing referral data for deleted user: ${userId}`);

    // Check if this user was referred by someone
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData) {
      console.log('⚠️ User document not found, skipping referral cleanup');
      return result;
    }

    const referredBy = userData.referredBy;

    // Handle if this user WAS REFERRED (they used someone's code)
    if (referredBy) {
      console.log(`👤 User was referred by: ${referredBy}`);
      await handleRefereeAccountDeletion(userId, referredBy, result);
    }

    // Handle if this user WAS A REFERRER (others used their code)
    await handleReferrerAccountDeletion(userId, result);

    result.success = true;
    console.log(`✅ Referral cleanup completed for user ${userId}`);
    return result;

  } catch (error) {
    console.error(`❌ Error handling referral user deletion: ${error}`);
    result.errors.push(error instanceof Error ? error.message : String(error));
    return result;
  }
}

/**
 * Handle when a REFERRED user (referee) deletes their account
 * - Notify the referrer
 * - Update referrer's stats
 * - Mark verification as deleted
 */
async function handleRefereeAccountDeletion(
  deletedUserId: string,
  referrerId: string,
  result: any
): Promise<void> {
  try {
    console.log(`🎯 Handling referee deletion for referrer: ${referrerId}`);

    // 1. Get the verification document
    const verificationRef = db.collection('referralVerifications').doc(deletedUserId);
    const verificationDoc = await verificationRef.get();

    if (!verificationDoc.exists) {
      console.log('⚠️ No verification document found');
      return;
    }

    const verificationData = verificationDoc.data()!;
    const wasVerified = verificationData.verificationStatus === 'verified';
    const rewardAwarded = verificationData.rewardAwarded || false;

    // 2. Mark verification as deleted (don't delete, keep for audit)
    await verificationRef.update({
      verificationStatus: 'deleted',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      deletedReason: 'User account deleted',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`✅ Marked verification as deleted for user ${deletedUserId}`);
    result.verificationsMarked = 1;

    // 3. Update referrer's stats
    const statsRef = db.collection('referralStats').doc(referrerId);
    const statsDoc = await statsRef.get();

    if (statsDoc.exists) {
      const updates: any = {
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Decrement totalReferred (they signed up but deleted account)
      updates.totalReferred = admin.firestore.FieldValue.increment(-1);

      // If they were verified, decrement that too
      if (wasVerified) {
        updates.totalVerified = admin.firestore.FieldValue.increment(-1);
      }

      // If they were pending, decrement pending
      if (verificationData.verificationStatus === 'pending') {
        updates.pendingVerifications = admin.firestore.FieldValue.increment(-1);
      }

      await statsRef.update(updates);
      
      console.log(`✅ Updated referrer stats for ${referrerId}`);
      result.statsUpdated = true;
    }

    // 4. Deactivate any referral code used
    const referralCode = verificationData.referralCode;
    if (referralCode) {
      const codeQuery = await db.collection('referralCodes')
        .where('code', '==', referralCode)
        .limit(1)
        .get();

      if (!codeQuery.empty) {
        const codeDoc = codeQuery.docs[0];
        await codeDoc.ref.update({
          totalRedemptions: admin.firestore.FieldValue.increment(-1),
          lastUsedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Updated referral code redemption count`);
      }
    }

    // 5. Notify the referrer
    try {
      const referrerDoc = await db.collection('users').doc(referrerId).get();
      const referrerData = referrerDoc.data();
      
      if (referrerData) {
        // Send notification using the standard referral notification system
        // The notification template will handle locale automatically
        await sendReferralNotification(
          referrerId,
          NotificationType.FRIEND_DELETED,
          {
            wasVerified: wasVerified ? 'true' : 'false',
          }
        );

        console.log(`✅ Notification sent to referrer ${referrerId}`);
        result.referrerNotified = true;
      }
    } catch (notificationError) {
      console.error(`⚠️ Failed to send notification to referrer: ${notificationError}`);
      result.errors.push('Failed to notify referrer');
      // Don't fail the whole process if notification fails
    }

    // 6. Log the deletion for audit purposes
    await db.collection('referralFraudLogs').add({
      userId: deletedUserId,
      action: 'user_deleted',
      referrerId: referrerId,
      wasVerified: wasVerified,
      rewardAwarded: rewardAwarded,
      reason: 'User account deleted',
      performedBy: 'system',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        verificationStatus: verificationData.verificationStatus,
        fraudScore: verificationData.fraudScore || 0,
        checklist: verificationData.checklist || {}
      }
    });

    console.log(`✅ Audit log created for deleted user ${deletedUserId}`);

  } catch (error) {
    console.error(`❌ Error handling referee account deletion: ${error}`);
    result.errors.push(`Referee cleanup failed: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * Handle when a REFERRER deletes their account
 * - Deactivate their referral code
 * - Mark their stats as deleted
 * - Update all their referral verifications
 */
async function handleReferrerAccountDeletion(
  deletedUserId: string,
  result: any
): Promise<void> {
  try {
    console.log(`🎯 Checking if user was a referrer: ${deletedUserId}`);

    // 1. Deactivate their referral code
    const codeQuery = await db.collection('referralCodes')
      .where('userId', '==', deletedUserId)
      .limit(1)
      .get();

    if (!codeQuery.empty) {
      const codeDoc = codeQuery.docs[0];
      await codeDoc.ref.update({
        isActive: false,
        deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deactivatedReason: 'User account deleted'
      });
      console.log(`✅ Deactivated referral code for user ${deletedUserId}`);
    }

    // 2. Mark referral stats as deleted (keep for audit)
    const statsRef = db.collection('referralStats').doc(deletedUserId);
    const statsDoc = await statsRef.get();

    if (statsDoc.exists) {
      await statsRef.update({
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`✅ Marked referral stats as deleted for user ${deletedUserId}`);
    }

    // 3. Update all verifications where this user was the referrer
    const verificationsQuery = await db.collection('referralVerifications')
      .where('referrerId', '==', deletedUserId)
      .get();

    if (!verificationsQuery.empty) {
      const batch = db.batch();
      
      verificationsQuery.docs.forEach(doc => {
        batch.update(doc.ref, {
          referrerDeleted: true,
          referrerDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await batch.commit();
      console.log(`✅ Updated ${verificationsQuery.size} verifications for deleted referrer`);
      result.verificationsMarked += verificationsQuery.size;
    }

    // 4. Mark all rewards as referrer deleted
    const rewardsQuery = await db.collection('referralRewards')
      .where('referrerId', '==', deletedUserId)
      .get();

    if (!rewardsQuery.empty) {
      const batch = db.batch();
      
      rewardsQuery.docs.forEach(doc => {
        batch.update(doc.ref, {
          referrerDeleted: true,
          referrerDeletedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await batch.commit();
      console.log(`✅ Updated ${rewardsQuery.size} rewards for deleted referrer`);
    }

  } catch (error) {
    console.error(`❌ Error handling referrer account deletion: ${error}`);
    result.errors.push(`Referrer cleanup failed: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * Get referrer stats summary for logging
 */
export async function getReferrerStatsSummary(referrerId: string): Promise<any> {
  try {
    const statsDoc = await db.collection('referralStats').doc(referrerId).get();
    if (!statsDoc.exists) {
      return null;
    }
    
    return statsDoc.data();
  } catch (error) {
    console.error(`Error getting referrer stats: ${error}`);
    return null;
  }
}

