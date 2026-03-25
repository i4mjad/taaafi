import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { executeAccountDeletion } from './executeAccountDeletion';

const GRACE_PERIOD_DAYS = 30;
const GRACE_PERIOD_MS = GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000;

/**
 * Daily scheduled function that automatically processes account deletion requests
 * that have passed the 30-day grace period.
 *
 * Queries accountDeleteRequests for pending (not canceled, not processed) requests
 * older than 30 days and executes full account deletion for each.
 */
export const processExpiredDeletionRequests = onSchedule(
  {
    schedule: '0 3 * * *', // Daily at 03:00 UTC
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    const db = admin.firestore();
    const cutoffDate = new Date(Date.now() - GRACE_PERIOD_MS);

    console.log(
      `[AUTO-DELETION] Starting daily sweep. Grace period cutoff: ${cutoffDate.toISOString()}`
    );

    // Query pending, non-canceled requests
    const snapshot = await db
      .collection('accountDeleteRequests')
      .where('isProcessed', '==', false)
      .where('isCanceled', '==', false)
      .get();

    if (snapshot.empty) {
      console.log('[AUTO-DELETION] No pending deletion requests found.');
      return;
    }

    // Filter to only those that have passed the 30-day grace period
    const expiredRequests = snapshot.docs.filter((doc) => {
      const data = doc.data();
      const requestedAt: FirebaseFirestore.Timestamp | undefined = data.requestedAt;
      if (!requestedAt) return false;
      return requestedAt.toDate() <= cutoffDate;
    });

    console.log(
      `[AUTO-DELETION] ${snapshot.size} pending requests found, ${expiredRequests.length} past grace period.`
    );

    if (expiredRequests.length === 0) {
      return;
    }

    let successCount = 0;
    let failureCount = 0;

    for (const requestDoc of expiredRequests) {
      const data = requestDoc.data();
      const userId: string = data.userId;

      console.log(`[AUTO-DELETION] Processing request ${requestDoc.id} for user ${userId}`);

      try {
        await executeAccountDeletion(userId, 'system-scheduled');

        // Mark the deletion request as processed
        await requestDoc.ref.update({
          isProcessed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          processedBy: 'system-scheduled',
        });

        successCount++;
        console.log(`[AUTO-DELETION] ✅ Successfully deleted account for user ${userId}`);
      } catch (error: any) {
        failureCount++;
        console.error(
          `[AUTO-DELETION] ❌ Failed to delete account for user ${userId}:`,
          error.message
        );

        // Record the failure on the request doc so admins can investigate
        try {
          await requestDoc.ref.update({
            lastAutoAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
            lastAutoAttemptError: error.message,
          });
        } catch (updateError) {
          console.error(
            `[AUTO-DELETION] Failed to record error on request ${requestDoc.id}:`,
            updateError
          );
        }
        // Continue processing remaining requests
      }
    }

    console.log(
      `[AUTO-DELETION] Sweep complete. Success: ${successCount}, Failed: ${failureCount}`
    );
  }
);
