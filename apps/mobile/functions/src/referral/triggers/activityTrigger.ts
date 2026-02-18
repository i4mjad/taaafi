// functions/src/referral/triggers/activityTrigger.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isActionAlreadyCounted, markActionAsCounted } from '../helpers/actionTrackingHelper';
import { handleVerificationCompletion } from '../handlers/verificationHandler';
import { updateFraudScore } from '../fraud/fraudScoreCalculator';
import { ReferralVerification } from '../types/referral.types';
import { notifyReferrerAboutProgress, notifyRefereeAboutTaskCompletion } from '../notifications/notificationHelper';

/**
 * Firestore trigger that tracks activity subscription for verification checklist.
 * Marks the activityStarted requirement as completed when user subscribes to an activity.
 */
export const onActivitySubscribed = functions.firestore
  .document('users/{userId}/ongoing_activities/{activityId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const activityId = context.params.activityId;
    const activityData = snap.data();
    const isDeleted = activityData?.isDeleted;

    // Skip deleted activities
    if (isDeleted) {
      console.log(`ℹ️ Activity ${activityId} is deleted, skipping`);
      return;
    }

    const db = admin.firestore();
    const verificationRef = db.collection('referralVerifications').doc(userId);
    const verificationDoc = await verificationRef.get();

    // Check if user has a pending verification
    if (!verificationDoc.exists) {
      console.log(`ℹ️ No verification document for user: ${userId}`);
      return;
    }

    const verification = verificationDoc.data() as ReferralVerification;

    // Skip if already verified or blocked
    if (verification.verificationStatus !== 'pending') {
      console.log(`ℹ️ User ${userId} verification status is ${verification.verificationStatus}`);
      return;
    }

    // Skip if activityStarted already completed
    if (verification.checklist.activityStarted.completed) {
      console.log(`ℹ️ User ${userId} has already completed activityStarted`);
      return;
    }

    // Check if this activity was already counted
    const alreadyCounted = await isActionAlreadyCounted(userId, 'activityStarted', activityId);
    if (alreadyCounted) {
      console.log(`ℹ️ Activity ${activityId} already counted for user ${userId}`);
      return;
    }

    // Mark activityStarted as completed
    const updateData: any = {
      'checklist.activityStarted.completed': true,
      'checklist.activityStarted.completedAt': admin.firestore.FieldValue.serverTimestamp(),
      'checklist.activityStarted.activityId': activityId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await verificationRef.update(updateData);

    // Mark this action as counted
    await markActionAsCounted(userId, 'activityStarted', activityId);

    console.log(`✅ Activity subscription tracked for user ${userId}: started activity ${activityId}`);

    // Send notifications
    try {
      // Count total completed tasks
      const totalTasks = 6;
      const completedTasks = Object.values(verification.checklist).filter(
        (task: any) => task.completed
      ).length + 1; // +1 for this task that just completed

      // Notify referee about task completion
      await notifyRefereeAboutTaskCompletion(
        userId,
        'Start 1 Recovery Activity',
        completedTasks,
        totalTasks
      );

      // Notify referrer about progress
      await notifyReferrerAboutProgress(
        verification.referrerId,
        userId,
        'Started a recovery activity'
      );

      console.log('✅ Task completion notifications sent');
    } catch (notificationError) {
      console.error('⚠️ Error sending task notifications:', notificationError);
    }

    // Update fraud score
    try {
      await updateFraudScore(userId);
    } catch (error) {
      console.error(`⚠️ Error updating fraud score for user ${userId}:`, error);
      // Don't fail the main operation if fraud score update fails
    }

    // Check if verification is complete
    await handleVerificationCompletion(userId);
  });

