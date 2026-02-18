// functions/src/referral/helpers/verificationStatus.ts
import * as admin from 'firebase-admin';
import { ReferralVerification, VerificationRequirements } from '../types/referral.types';

/**
 * Retrieves verification requirements configuration.
 * In a real implementation this could be stored in Firestore or remote config.
 */
export async function getVerificationRequirements(): Promise<VerificationRequirements> {
  // Placeholder static config – adjust as needed.
  return {
    minAccountAgeDays: 7,
    minForumPosts: 3,
    minInteractions: 5,
    minGroupMessages: 3,
    minActivitiesStarted: 1,
  };
}

/**
 * Checks if all checklist items are completed for a user.
 */
export async function isChecklistComplete(userId: string): Promise<boolean> {
  const doc = await admin.firestore().collection('referralVerifications').doc(userId).get();
  if (!doc.exists) return false;
  const data = doc.data() as ReferralVerification;
  const checklist = data.checklist;
  return Object.values(checklist).every((item) => item.completed);
}

/**
 * Marks a user as verified and updates the verification document.
 */
export async function markUserAsVerified(userId: string): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.update({
    verificationStatus: 'verified',
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Blocks a user for fraud, recording reason and score.
 */
export async function blockUserForFraud(
  userId: string,
  reason: string,
  score: number
): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.update({
    verificationStatus: 'blocked',
    isBlocked: true,
    blockedReason: reason,
    blockedAt: admin.firestore.FieldValue.serverTimestamp(),
    fraudScore: score,
  });
}

/**
 * Retrieves the verification document for debugging or UI display.
 */
export async function getVerificationDoc(
  userId: string
): Promise<ReferralVerification | null> {
  const doc = await admin.firestore().collection('referralVerifications').doc(userId).get();
  if (!doc.exists) return null;
  return doc.data() as ReferralVerification;
}
