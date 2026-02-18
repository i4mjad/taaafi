// functions/src/referral/generateUserReferralCode.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {generateAndEnsureUniqueCode} from './helpers/codeGenerator';

/**
 * Callable function for users to manually generate their referral code.
 * This allows users to create a code if it wasn't auto-generated during signup.
 * 
 * Security:
 * - Requires authentication
 * - Rate limited to prevent abuse
 * - Checks if code already exists
 */
export const generateUserReferralCode = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to generate a referral code.'
      );
    }

    const userId = context.auth.uid;
    const db = admin.firestore();

    try {
      console.log(`📝 User ${userId} requesting referral code generation`);

      // Check if user already has a referral code
      const existingCodeQuery = await db
        .collection('referralCodes')
        .where('userId', '==', userId)
        .where('isActive', '==', true)
        .limit(1)
        .get();

      if (!existingCodeQuery.empty) {
        console.log(`⚠️ User ${userId} already has a referral code`);
        throw new functions.https.HttpsError(
          'already-exists',
          'You already have an active referral code.'
        );
      }

      // Rate limiting: Check recent attempts
      // Allow max 3 attempts per day
      const oneDayAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 24 * 60 * 60 * 1000)
      );

      const recentAttemptsQuery = await db
        .collection('referralCodeGenerationAttempts')
        .where('userId', '==', userId)
        .where('attemptedAt', '>', oneDayAgo)
        .get();

      if (recentAttemptsQuery.size >= 3) {
        console.log(`🚫 User ${userId} exceeded daily generation limit`);
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'You have exceeded the daily limit for code generation attempts. Please try again tomorrow.'
        );
      }

      // Log attempt
      await db.collection('referralCodeGenerationAttempts').add({
        userId,
        attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Get user details for code generation
      const userDoc = await db.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.log(`⚠️ User document not found for ${userId}`);
        throw new functions.https.HttpsError(
          'not-found',
          'User profile not found. Please ensure your profile is set up.'
        );
      }

      const userData = userDoc.data()!;
      console.log(`📋 User data: displayName=${userData.displayName}, email=${userData.email}`);
      
      const userName = userData.displayName || userData.name || '';
      const userEmail = userData.email || context.auth.token.email || '';

      console.log(`🔤 Generating code with: name="${userName}", email="${userEmail}"`);

      // Generate unique referral code
      const code = await generateAndEnsureUniqueCode(userName, userEmail);
      console.log(`✨ Generated unique code: ${code}`);

      // Create referral code document
      const referralCodeData = {
        userId,
        code,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        totalRedemptions: 0,
        lastUsedAt: null,
        generatedManually: true, // Track that this was user-initiated
      };

      await db.collection('referralCodes').add(referralCodeData);

      // Initialize referral stats for the user if not exists
      const statsDoc = await db.collection('referralStats').doc(userId).get();
      if (!statsDoc.exists) {
        await db.collection('referralStats').doc(userId).set({
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
      }

      console.log(`✅ Successfully generated referral code ${code} for user ${userId}`);

      return {
        success: true,
        code,
        message: 'Referral code generated successfully!',
      };
    } catch (error) {
      console.error('Error generating referral code:', error);

      // If it's already a Functions error, re-throw it
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Generic error
      throw new functions.https.HttpsError(
        'internal',
        'An error occurred while generating your referral code. Please try again later.'
      );
    }
  }
);

