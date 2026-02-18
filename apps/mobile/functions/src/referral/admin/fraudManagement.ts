// functions/src/referral/admin/fraudManagement.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { calculateCompleteFraudScore } from '../fraud/fraudScoreCalculator';
import { approveUser, manualBlockUser } from '../fraud/fraudActions';
import { runPatternDetection } from '../fraud/patternDetection';

const db = admin.firestore();

/**
 * Verifies that the caller is an admin
 */
async function verifyAdmin(context: functions.https.CallableContext): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const userDoc = await db.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User not found');
  }

  const role = userDoc.data()?.role;
  if (role !== 'admin' && role !== 'founder') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'User does not have admin privileges'
    );
  }
}

/**
 * Admin callable function to manually approve a flagged user
 */
export const approveReferralVerification = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify admin
      await verifyAdmin(context);

      const { userId, notes } = data;

      if (!userId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'userId is required'
        );
      }

      const adminId = context.auth!.uid;
      await approveUser(userId, adminId, notes);

      return {
        success: true,
        message: `User ${userId} approved successfully`,
      };
    } catch (error: any) {
      console.error('Error in approveReferralVerification:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to approve user'
      );
    }
  }
);

/**
 * Admin callable function to manually block a user
 */
export const blockReferralUser = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin
    await verifyAdmin(context);

    const { userId, reason } = data;

    if (!userId || !reason) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userId and reason are required'
      );
    }

    const adminId = context.auth!.uid;
    await manualBlockUser(userId, adminId, reason);

    return {
      success: true,
      message: `User ${userId} blocked successfully`,
    };
  } catch (error: any) {
    console.error('Error in blockReferralUser:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to block user'
    );
  }
});

/**
 * Admin callable function to get detailed fraud information for a user
 */
export const getFraudDetails = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin
    await verifyAdmin(context);

    const { userId } = data;

    if (!userId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userId is required'
      );
    }

    // Get verification document
    const verificationDoc = await db
      .collection('referralVerifications')
      .doc(userId)
      .get();

    if (!verificationDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Verification document not found'
      );
    }

    const verification = verificationDoc.data();
    const referrerId = verification?.referrerId;

    // Run all fraud checks
    const fraudScoreResult = await calculateCompleteFraudScore(userId);

    // Run pattern detection
    const patternResult = await runPatternDetection(userId, referrerId);

    // Get fraud logs for this user
    const logsQuery = await db
      .collection('referralFraudLogs')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const logs = logsQuery.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get user info
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    return {
      success: true,
      userId,
      verification: {
        status: verification?.verificationStatus,
        currentTier: verification?.currentTier,
        isBlocked: verification?.isBlocked,
        blockedReason: verification?.blockedReason,
        fraudScore: verification?.fraudScore,
        fraudFlags: verification?.fraudFlags || [],
        checklist: verification?.checklist,
      },
      fraudAnalysis: {
        totalScore: fraudScoreResult.totalScore,
        flags: fraudScoreResult.flags,
        checks: fraudScoreResult.checks,
      },
      patternDetection: {
        isCoordinated: patternResult.isCoordinated,
        matchesTemplate: patternResult.matchesTemplate,
      },
      userInfo: {
        email: userData?.email,
        displayName: userData?.displayName,
        devicesIds: userData?.devicesIds || [],
        userFirstDate: userData?.userFirstDate,
      },
      fraudLogs: logs,
    };
  } catch (error: any) {
    console.error('Error in getFraudDetails:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to get fraud details'
    );
  }
});

/**
 * Admin callable function to get a list of users flagged for review
 */
export const getFlaggedUsers = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin
    await verifyAdmin(context);

    const { limit = 50 } = data;

    // Get users with needs_manual_review flag
    const flaggedQuery = await db
      .collection('referralVerifications')
      .where('fraudFlags', 'array-contains', 'needs_manual_review')
      .where('verificationStatus', '==', 'pending')
      .orderBy('lastCheckedAt', 'desc')
      .limit(limit)
      .get();

    const flaggedUsers = await Promise.all(
      flaggedQuery.docs.map(async (doc) => {
        const verification = doc.data();
        const userId = doc.id;

        // Get user info
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.exists ? userDoc.data() : null;

        return {
          userId,
          fraudScore: verification.fraudScore,
          fraudFlags: verification.fraudFlags || [],
          lastCheckedAt: verification.lastCheckedAt,
          signupDate: verification.signupDate,
          email: userData?.email,
          displayName: userData?.displayName,
          checklist: verification.checklist,
        };
      })
    );

    return {
      success: true,
      users: flaggedUsers,
      total: flaggedUsers.length,
    };
  } catch (error: any) {
    console.error('Error in getFlaggedUsers:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to get flagged users'
    );
  }
});

/**
 * Admin callable function to recalculate fraud score for a user
 */
export const recalculateFraudScore = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify admin
      await verifyAdmin(context);

      const { userId } = data;

      if (!userId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'userId is required'
        );
      }

      const fraudScoreResult = await calculateCompleteFraudScore(userId);

      // Update verification document
      await db
        .collection('referralVerifications')
        .doc(userId)
        .update({
          fraudScore: fraudScoreResult.totalScore,
          fraudFlags: fraudScoreResult.flags,
          lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      return {
        success: true,
        fraudScore: fraudScoreResult.totalScore,
        flags: fraudScoreResult.flags,
        checks: fraudScoreResult.checks,
      };
    } catch (error: any) {
      console.error('Error in recalculateFraudScore:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to recalculate fraud score'
      );
    }
  }
);

