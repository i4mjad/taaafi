// functions/src/referral/scheduledChecks.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { ReferralVerification } from './types/referral.types';

/**
 * Daily scheduled function to evaluate pending verification documents.
 * NOTE: Account age requirement has been removed.
 * This function is now disabled but kept for future use if needed.
 */
export const checkPendingVerificationAges = functions.pubsub
  .schedule('0 2 * * *') // Runs daily at 02:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    // Account age requirement removed - function disabled
    console.log(`ℹ️ Scheduled check disabled - account age requirement removed`);
    return null;
  });
