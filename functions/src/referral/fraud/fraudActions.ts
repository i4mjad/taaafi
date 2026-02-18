// functions/src/referral/fraud/fraudActions.ts
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Blocks a user for fraud
 * Updates verification document and referrer stats
 */
export async function blockUserForFraud(
  userId: string,
  reason: string,
  score: number
): Promise<void> {
  try {
    // Get verification document
    const verificationRef = db.collection('referralVerifications').doc(userId);
    const verificationDoc = await verificationRef.get();

    if (!verificationDoc.exists) {
      console.log(`⚠️ No verification document found for user ${userId}`);
      return;
    }

    const verification = verificationDoc.data();
    const referrerId = verification?.referrerId;

    // Update verification document
    await verificationRef.update({
      isBlocked: true,
      blockedReason: reason,
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
      verificationStatus: 'blocked',
    });

    // Update referrer stats
    if (referrerId) {
      const referrerStatsRef = db.collection('referralStats').doc(referrerId);
      await referrerStatsRef.update({
        blockedReferrals: admin.firestore.FieldValue.increment(1),
        pendingVerifications: admin.firestore.FieldValue.increment(-1),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Log to fraud audit collection
    await logFraudAction(userId, 'auto_block', score, [], reason, 'system');

    console.log(`🚫 User ${userId} blocked for fraud: ${reason} (score: ${score})`);
  } catch (error) {
    console.error('Error blocking user for fraud:', error);
    throw error;
  }
}

/**
 * Flags a user for manual review
 * Adds flag to verification document
 */
export async function flagUserForReview(
  userId: string,
  score: number
): Promise<void> {
  try {
    const verificationRef = db.collection('referralVerifications').doc(userId);

    // Add 'needs_manual_review' flag
    await verificationRef.update({
      fraudFlags: admin.firestore.FieldValue.arrayUnion('needs_manual_review'),
      lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log to fraud audit collection
    await logFraudAction(
      userId,
      'flagged',
      score,
      ['needs_manual_review'],
      'Medium fraud score - needs review',
      'system'
    );

    console.log(`⚠️ User ${userId} flagged for review (fraud score: ${score})`);
  } catch (error) {
    console.error('Error flagging user for review:', error);
    throw error;
  }
}

/**
 * Logs fraud actions to audit collection
 */
export async function logFraudAction(
  userId: string,
  action: 'auto_block' | 'flagged' | 'manual_block' | 'approved',
  fraudScore: number,
  fraudFlags: string[],
  reason: string,
  performedBy: string
): Promise<void> {
  try {
    await db.collection('referralFraudLogs').add({
      userId,
      action,
      fraudScore,
      fraudFlags,
      reason,
      performedBy,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Error logging fraud action:', error);
    // Don't throw - logging should not fail the main operation
  }
}

/**
 * Admin function to manually approve a flagged user
 */
export async function approveUser(
  userId: string,
  adminId: string,
  notes?: string
): Promise<void> {
  try {
    const verificationRef = db.collection('referralVerifications').doc(userId);
    const verificationDoc = await verificationRef.get();

    if (!verificationDoc.exists) {
      throw new Error('Verification document not found');
    }

    const verification = verificationDoc.data();
    const referrerId = verification?.referrerId;

    // Update verification to verified status
    await verificationRef.update({
      verificationStatus: 'verified',
      currentTier: 'verified',
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      fraudFlags: [], // Clear fraud flags
      isBlocked: false,
      blockedReason: null,
    });

    // Update referrer stats
    if (referrerId) {
      const referrerStatsRef = db.collection('referralStats').doc(referrerId);
      await referrerStatsRef.update({
        totalVerified: admin.firestore.FieldValue.increment(1),
        pendingVerifications: admin.firestore.FieldValue.increment(-1),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Log approval
    await logFraudAction(
      userId,
      'approved',
      verification?.fraudScore || 0,
      [],
      notes || 'Manually approved by admin',
      adminId
    );

    console.log(`✅ User ${userId} manually approved by admin ${adminId}`);
  } catch (error) {
    console.error('Error approving user:', error);
    throw error;
  }
}

/**
 * Admin function to manually block a user
 */
export async function manualBlockUser(
  userId: string,
  adminId: string,
  reason: string
): Promise<void> {
  try {
    const verificationRef = db.collection('referralVerifications').doc(userId);
    const verificationDoc = await verificationRef.get();

    if (!verificationDoc.exists) {
      throw new Error('Verification document not found');
    }

    const verification = verificationDoc.data();
    const referrerId = verification?.referrerId;

    // Update verification document
    await verificationRef.update({
      isBlocked: true,
      blockedReason: `Manual block: ${reason}`,
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
      verificationStatus: 'blocked',
    });

    // Update referrer stats
    if (referrerId) {
      const referrerStatsRef = db.collection('referralStats').doc(referrerId);
      await referrerStatsRef.update({
        blockedReferrals: admin.firestore.FieldValue.increment(1),
        pendingVerifications: admin.firestore.FieldValue.increment(-1),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Log manual block
    await logFraudAction(
      userId,
      'manual_block',
      verification?.fraudScore || 0,
      verification?.fraudFlags || [],
      reason,
      adminId
    );

    console.log(`🚫 User ${userId} manually blocked by admin ${adminId}: ${reason}`);
  } catch (error) {
    console.error('Error manually blocking user:', error);
    throw error;
  }
}

