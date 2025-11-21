// functions/src/referral/helpers/fraudDetection.ts
import * as admin from 'firebase-admin';
import { ReferralVerification } from '../types/referral.types';

/**
 * Calculates a fraud score for a user based on various heuristics.
 * Returns a numeric score; higher means more suspicious.
 */
export async function calculateFraudScore(userId: string): Promise<number> {
  // Placeholder implementation – real logic would analyse device IDs, IPs, posting patterns, etc.
  // For now, return 0 (no fraud detected).
  return 0;
}

/**
 * Checks if the devices used by the referrer and referee overlap.
 */
export async function checkDeviceOverlap(userId: string, referrerId: string): Promise<boolean> {
  // Placeholder – actual implementation would compare stored device identifiers.
  return false;
}

/**
 * Analyses posting patterns for suspicious activity.
 * Returns a numeric risk score.
 */
export async function checkPostingPattern(userId: string): Promise<number> {
  // Placeholder – implement pattern analysis.
  return 0;
}

/**
 * Checks interaction concentration – e.g., interacting only with a single user.
 * Returns a numeric score.
 */
export async function checkInteractionConcentration(userId: string): Promise<number> {
  // Placeholder – implement interaction analysis.
  return 0;
}

/**
 * Updates the fraud score stored in the verification document.
 */
export async function updateFraudScore(userId: string, score: number): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.update({ fraudScore: score });
}

/**
 * Adds a fraud flag to the verification document.
 */
export async function addFraudFlag(userId: string, flag: string): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.update({
    fraudFlags: admin.firestore.FieldValue.arrayUnion(flag),
    isBlocked: true,
  });
}
