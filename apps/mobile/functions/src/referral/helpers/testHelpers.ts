// functions/src/referral/helpers/testHelpers.ts
import * as admin from 'firebase-admin';
import { ReferralVerification } from '../types/referral.types';

/**
 * Retrieves the full verification document for debugging or UI display.
 */
export async function getVerificationDebugInfo(userId: string): Promise<ReferralVerification | null> {
  const doc = await admin.firestore().collection('referralVerifications').doc(userId).get();
  if (!doc.exists) return null;
  return doc.data() as ReferralVerification;
}

/**
 * Manually triggers a verification check for a user (admin only).
 * This can be used in testing or admin dashboards.
 */
export async function manualVerificationCheck(userId: string): Promise<{ success: boolean; message: string }> {
  try {
    // For simplicity, just re-run the checklist progress calculation.
    // In a real implementation you would invoke the same logic as the scheduled function.
    const progress = await import('./checklistHelper').then(m => m.getChecklistProgress(userId));
    return { success: true, message: `Checklist progress: ${progress}%` };
  } catch (e) {
    return { success: false, message: `Error: ${e}` };
  }
}

/**
 * Resets verification data for a user (testing only, staging environment).
 */
export async function resetVerification(userId: string): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.delete();
}
