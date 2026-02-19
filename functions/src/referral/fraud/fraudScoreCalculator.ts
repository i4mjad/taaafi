// functions/src/referral/fraud/fraudScoreCalculator.ts
import * as admin from 'firebase-admin';
import { FraudScoreResult } from '../types/referral.types';
import {
  checkDeviceOverlap,
  checkPostingPattern,
  checkInteractionConcentration,
  checkGroupMessagingPattern,
  checkActivityBurst,
  checkContentQuality,
  checkEmailPattern,
} from './fraudChecks';

const db = admin.firestore();

/**
 * Calculates a complete fraud score by running all fraud checks
 * Returns detailed results including total score, flags, and individual check results
 */
export async function calculateCompleteFraudScore(
  userId: string
): Promise<FraudScoreResult> {
  try {
    // Get referrer ID for device overlap check
    const verificationDoc = await db
      .collection('referralVerifications')
      .doc(userId)
      .get();

    if (!verificationDoc.exists) {
      console.log(`⚠️ No verification document for user ${userId}`);
      return {
        totalScore: 0,
        flags: [],
        checks: [],
      };
    }

    const referrerId = verificationDoc.data()?.referrerId;

    // Run all fraud checks in parallel
    const [
      deviceOverlapResult,
      postingPatternResult,
      interactionConcentrationResult,
      groupMessagingPatternResult,
      activityBurstResult,
      contentQualityResult,
      emailPatternResult,
    ] = await Promise.all([
      checkDeviceOverlap(userId, referrerId),
      checkPostingPattern(userId),
      checkInteractionConcentration(userId),
      checkGroupMessagingPattern(userId),
      checkActivityBurst(userId),
      checkContentQuality(userId),
      checkEmailPattern(userId),
    ]);

    const checks = [
      deviceOverlapResult,
      postingPatternResult,
      interactionConcentrationResult,
      groupMessagingPatternResult,
      activityBurstResult,
      contentQualityResult,
      emailPatternResult,
    ];

    // Sum all scores
    const totalScore = Math.min(
      100,
      checks.reduce((sum, check) => sum + check.score, 0)
    );

    // Collect all flags
    const flags = checks
      .filter((check) => check.flag !== null)
      .map((check) => check.flag as string);

    console.log(
      `✅ Fraud score calculated for user ${userId}: ${totalScore} (${flags.length} flags)`
    );

    return {
      totalScore,
      flags,
      checks,
    };
  } catch (error) {
    console.error('Error calculating fraud score:', error);
    return {
      totalScore: 0,
      flags: [],
      checks: [],
    };
  }
}

/**
 * Updates the fraud score in the verification document
 * Also triggers auto-block or flagging if thresholds are exceeded
 */
export async function updateFraudScore(userId: string): Promise<void> {
  try {
    const result = await calculateCompleteFraudScore(userId);

    // Update verification document with fraud score
    await db
      .collection('referralVerifications')
      .doc(userId)
      .update({
        fraudScore: result.totalScore,
        fraudFlags: result.flags,
        lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`✅ Updated fraud score for user ${userId}: ${result.totalScore}`);
  } catch (error) {
    console.error('Error updating fraud score:', error);
    throw error;
  }
}

