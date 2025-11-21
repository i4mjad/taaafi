// functions/src/referral/handlers/verificationHandler.ts
import * as admin from 'firebase-admin';
import { ReferralVerification } from '../types/referral.types';
import { isChecklistComplete } from '../helpers/verificationStatus';
import { calculateCompleteFraudScore } from '../fraud/fraudScoreCalculator';
import { blockUserForFraud, flagUserForReview } from '../fraud/fraudActions';
import { checkAccountAge } from '../helpers/checklistHelper';
import { sendReferralNotification, getUserDisplayName } from '../notifications/notificationHelper';
import { NotificationType } from '../notifications/notificationTypes';

/**
 * Handles the completion of a user's verification checklist.
 * This function should be called after any checklist item is updated.
 * It checks if all requirements are met and takes appropriate action.
 * 
 * @param userId - The user's UID
 */
export async function handleVerificationCompletion(userId: string): Promise<void> {
  const db = admin.firestore();
  
  // Get the verification document
  const verificationRef = db.collection('referralVerifications').doc(userId);
  const verificationDoc = await verificationRef.get();
  
  if (!verificationDoc.exists) {
    console.log(`⚠️ No verification document found for user: ${userId}`);
    return;
  }
  
  const verification = verificationDoc.data() as ReferralVerification;
  
  // Skip if already verified or blocked
  if (verification.verificationStatus !== 'pending') {
    console.log(`ℹ️ User ${userId} verification status is ${verification.verificationStatus}, skipping.`);
    return;
  }
  
  // Check if all checklist items are completed
  const allItemsCompleted = await isChecklistComplete(userId);
  
  if (!allItemsCompleted) {
    console.log(`ℹ️ User ${userId} has not completed all checklist items yet.`);
    return;
  }
  
  // Check if account age requirement is met (7 days)
  const accountAgeOk = await checkAccountAge(userId, 7);
  
  if (!accountAgeOk) {
    console.log(`ℹ️ User ${userId} has not met the 7-day account age requirement yet.`);
    return;
  }
  
  // Calculate comprehensive fraud score
  const fraudScoreResult = await calculateCompleteFraudScore(userId);
  const fraudScore = fraudScoreResult.totalScore;
  
  // Update fraud score in verification document
  await verificationRef.update({
    fraudScore: fraudScore,
    fraudFlags: fraudScoreResult.flags,
    lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  // Fraud thresholds
  const FRAUD_THRESHOLD_AUTO_BLOCK = 71;
  const FRAUD_THRESHOLD_MANUAL_REVIEW = 40;
  
  // Take action based on fraud score
  if (fraudScore >= FRAUD_THRESHOLD_AUTO_BLOCK) {
    // High risk: Block user automatically
    await blockUserForFraud(
      userId,
      `Automatic block: High fraud score (${fraudScore})`,
      fraudScore
    );
    
    console.log(`🚫 User ${userId} blocked due to high fraud score: ${fraudScore}`);
    
  } else if (fraudScore >= FRAUD_THRESHOLD_MANUAL_REVIEW) {
    // Medium risk: Flag for manual review
    await flagUserForReview(userId, fraudScore);
    
    console.log(`⚠️ User ${userId} flagged for review (fraud score: ${fraudScore})`);
    
  } else {
    // Low risk: Mark as verified
    await verificationRef.update({
      verificationStatus: 'verified',
      currentTier: 'verified',
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update referrer's stats
    const referrerStatsRef = db.collection('referralStats').doc(verification.referrerId);
    await referrerStatsRef.update({
      totalVerified: admin.firestore.FieldValue.increment(1),
      pendingVerifications: admin.firestore.FieldValue.increment(-1),
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Get updated stats to check for milestones
    const updatedStatsDoc = await referrerStatsRef.get();
    const updatedStats = updatedStatsDoc.data();
    const totalVerified = updatedStats?.totalVerified || 1;
    
    console.log(`✅ User ${userId} verified successfully! (fraud score: ${fraudScore})`);
    
    // Send notifications
    try {
      // Get display names
      const refereeName = await getUserDisplayName(userId);
      const referrerName = await getUserDisplayName(verification.referrerId);
      
      // Notify referee about verification completion
      await sendReferralNotification(
        userId,
        NotificationType.VERIFICATION_COMPLETE,
        {}
      );
      
      // Notify referrer about friend verification
      await sendReferralNotification(
        verification.referrerId,
        NotificationType.FRIEND_VERIFIED,
        {
          friendName: refereeName,
          progress: `${totalVerified}/5`,
        }
      );
      
      // Check if milestone reached (every 5 verifications)
      if (totalVerified % 5 === 0) {
        await sendReferralNotification(
          verification.referrerId,
          NotificationType.MILESTONE_REACHED,
          {
            reward: '1 month Premium',
          }
        );
        console.log(`🎁 Milestone notification sent to referrer ${verification.referrerId}`);
      }
      
      console.log("✅ Verification notifications sent successfully");
    } catch (notificationError) {
      // Log but don't fail the function if notifications fail
      console.error("⚠️ Error sending verification notifications:", notificationError);
    }
    
    // Note: Reward awarding will be implemented in Sprint 11
  }
}

