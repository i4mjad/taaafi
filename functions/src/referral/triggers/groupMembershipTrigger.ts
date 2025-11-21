// functions/src/referral/triggers/groupMembershipTrigger.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUserIdFromCPIdCached } from '../helpers/userHelper';
import { isActionAlreadyCounted, markActionAsCounted } from '../helpers/actionTrackingHelper';
import { handleVerificationCompletion } from '../handlers/verificationHandler';
import { updateFraudScore } from '../fraud/fraudScoreCalculator';
import { ReferralVerification } from '../types/referral.types';
import { notifyReferrerAboutProgress, notifyRefereeAboutTaskCompletion } from '../notifications/notificationHelper';

/**
 * Firestore trigger that tracks group membership creation for verification checklist.
 * Marks the groupJoined requirement as completed when user joins a group.
 */
export const onGroupMembershipCreated = functions.firestore
  .document('group_memberships/{membershipId}')
  .onCreate(async (snap, context) => {
    const membershipId = context.params.membershipId;
    const membershipData = snap.data();
    const cpId = membershipData?.cpId;
    const groupId = membershipData?.groupId;

    if (!cpId) {
      console.log(`⚠️ Group membership ${membershipId} has no cpId`);
      return;
    }

    if (!groupId) {
      console.log(`⚠️ Group membership ${membershipId} has no groupId`);
      return;
    }

    // Convert Community Profile ID to User UID
    const userId = await getUserIdFromCPIdCached(cpId);
    if (!userId) {
      console.log(`⚠️ Could not find user for CP ID: ${cpId}`);
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

    // Skip if groupJoined already completed
    if (verification.checklist.groupJoined.completed) {
      console.log(`ℹ️ User ${userId} has already completed groupJoined`);
      return;
    }

    // Check if this membership was already counted
    const alreadyCounted = await isActionAlreadyCounted(userId, 'groupJoined', membershipId);
    if (alreadyCounted) {
      console.log(`ℹ️ Group membership ${membershipId} already counted for user ${userId}`);
      return;
    }

    // Mark groupJoined as completed
    const updateData: any = {
      'checklist.groupJoined.completed': true,
      'checklist.groupJoined.completedAt': admin.firestore.FieldValue.serverTimestamp(),
      'checklist.groupJoined.groupId': groupId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await verificationRef.update(updateData);

    // Mark this action as counted
    await markActionAsCounted(userId, 'groupJoined', membershipId);

    console.log(`✅ Group join tracked for user ${userId}: joined group ${groupId}`);

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
        'Join a Group',
        completedTasks,
        totalTasks
      );

      // Notify referrer about progress
      await notifyReferrerAboutProgress(
        verification.referrerId,
        userId,
        'Joined a group'
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

