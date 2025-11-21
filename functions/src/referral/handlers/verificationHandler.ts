// functions/src/referral/handlers/verificationHandler.ts
import * as admin from 'firebase-admin';
import { ReferralVerification } from '../types/referral.types';
import { isChecklistComplete } from '../helpers/verificationStatus';
import { calculateFraudScore } from '../helpers/fraudDetection';
import { checkAccountAge } from '../helpers/checklistHelper';

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
  
  // Calculate final fraud score
  const fraudScore = await calculateFraudScore(userId);
  
  // Update fraud score in verification document
  await verificationRef.update({
    fraudScore,
    lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  // Fraud thresholds
  const FRAUD_THRESHOLD_HIGH = 70;
  const FRAUD_THRESHOLD_MEDIUM = 40;
  
  // Take action based on fraud score
  if (fraudScore > FRAUD_THRESHOLD_HIGH) {
    // High risk: Block user and notify admin
    await verificationRef.update({
      verificationStatus: 'blocked',
      isBlocked: true,
      blockedReason: `High fraud score: ${fraudScore}`,
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update referrer's stats (increment blocked count)
    const referrerStatsRef = db.collection('referralStats').doc(verification.referrerId);
    await referrerStatsRef.update({
      blockedReferrals: admin.firestore.FieldValue.increment(1),
      pendingVerifications: admin.firestore.FieldValue.increment(-1),
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`🚫 User ${userId} blocked due to high fraud score: ${fraudScore}`);
    
  } else if (fraudScore >= FRAUD_THRESHOLD_MEDIUM) {
    // Medium risk: Flag for manual review
    await verificationRef.update({
      fraudFlags: admin.firestore.FieldValue.arrayUnion('flagged_for_review'),
      lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
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
    
    console.log(`✅ User ${userId} verified successfully! (fraud score: ${fraudScore})`);
    
    // Note: Reward awarding will be implemented in Sprint 11
    // Note: Notifications will be implemented in Sprint 10
  }
}

