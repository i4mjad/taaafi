// functions/src/referral/triggers/groupMessageTrigger.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUserIdFromCPIdCached } from '../helpers/userHelper';
import { isActionAlreadyCounted, markActionAsCounted } from '../helpers/actionTrackingHelper';
import { handleVerificationCompletion } from '../handlers/verificationHandler';
import { updateFraudScore } from '../fraud/fraudScoreCalculator';
import { ReferralVerification } from '../types/referral.types';

/**
 * Firestore trigger that tracks group message creation for verification checklist.
 * Increments the groupMessages3 counter and marks as completed when 3 messages are sent
 * in the group the user joined.
 */
export const onGroupMessageCreated = functions.firestore
  .document('groups/{groupId}/group_messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageId = context.params.messageId;
    const groupId = context.params.groupId;
    const messageData = snap.data();
    const senderCpId = messageData?.senderCpId;

    if (!senderCpId) {
      console.log(`⚠️ Group message ${messageId} has no senderCpId`);
      return;
    }

    // Convert Community Profile ID to User UID
    const userId = await getUserIdFromCPIdCached(senderCpId);
    if (!userId) {
      console.log(`⚠️ Could not find user for CP ID: ${senderCpId}`);
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

    // Skip if groupMessages3 already completed
    if (verification.checklist.groupMessages3.completed) {
      console.log(`ℹ️ User ${userId} has already completed groupMessages3`);
      return;
    }

    // Verify this message is in the group they joined (if groupJoined is completed)
    const joinedGroupId = verification.checklist.groupJoined.groupId;
    if (joinedGroupId && joinedGroupId !== groupId) {
      console.log(`ℹ️ User ${userId} sent message in group ${groupId}, but joined group is ${joinedGroupId}`);
      return;
    }

    // Check if this message was already counted
    const alreadyCounted = await isActionAlreadyCounted(userId, 'groupMessage', messageId);
    if (alreadyCounted) {
      console.log(`ℹ️ Group message ${messageId} already counted for user ${userId}`);
      return;
    }

    // Increment the counter
    const currentCount = verification.checklist.groupMessages3.current || 0;
    const newCount = currentCount + 1;

    // Check if we've reached the requirement
    const completed = newCount >= 3;

    // Update the checklist item
    const updateData: any = {
      'checklist.groupMessages3.current': newCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (completed) {
      updateData['checklist.groupMessages3.completed'] = true;
      updateData['checklist.groupMessages3.completedAt'] = admin.firestore.FieldValue.serverTimestamp();
    }

    await verificationRef.update(updateData);

    // Mark this action as counted
    await markActionAsCounted(userId, 'groupMessage', messageId);

    console.log(`✅ Group message tracked for user ${userId}: ${newCount}/3 messages`);

    // Update fraud score
    try {
      await updateFraudScore(userId);
    } catch (error) {
      console.error(`⚠️ Error updating fraud score for user ${userId}:`, error);
      // Don't fail the main operation if fraud score update fails
    }

    // Check if verification is complete
    if (completed) {
      await handleVerificationCompletion(userId);
    }
  });

