// functions/src/referral/scheduledChecks.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { ReferralVerification } from './types/referral.types';

/**
 * Daily scheduled function to evaluate pending verification documents.
 * It checks the account age requirement (7 days) for each pending verification
 * and updates the corresponding checklist item if the requirement is met.
 */
export const checkPendingVerificationAges = functions.pubsub
  .schedule('0 2 * * *') // Runs daily at 02:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const pendingSnapshot = await db
      .collection('referralVerifications')
      .where('verificationStatus', '==', 'pending')
      .get();

    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    for (const doc of pendingSnapshot.docs) {
      const data = doc.data() as ReferralVerification;
      const userId = data.userId;

      // Retrieve the user document to calculate account age.
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) continue;
      const createdAt = userDoc.data()?.createdAt;
      if (!createdAt) continue;

      const createdDate = createdAt.toDate();
      const ageDays = (Date.now() - createdDate.getTime()) / (1000 * 60 * 60 * 24);

      if (ageDays >= 7 && !data.checklist.accountAge7Days.completed) {
        // Update checklist item to completed.
        const verificationRef = db.collection('referralVerifications').doc(userId);
        batch.update(verificationRef, {
          'checklist.accountAge7Days.completed': true,
          'checklist.accountAge7Days.completedAt': now,
          lastCheckedAt: now,
        });
      }
    }

    // Commit any updates.
    await batch.commit();
    console.log(`✅ Scheduled check completed. Processed ${pendingSnapshot.size} pending verifications.`);
    return null;
  });
