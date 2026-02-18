// functions/src/referral/triggers/interactionTrigger.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUserIdFromCPIdCached } from '../helpers/userHelper';
import { isActionAlreadyCounted, markActionAsCounted } from '../helpers/actionTrackingHelper';
import { handleVerificationCompletion } from '../handlers/verificationHandler';
import { updateFraudScore } from '../fraud/fraudScoreCalculator';
import { ReferralVerification } from '../types/referral.types';

/**
 * Firestore trigger that tracks interaction (like) creation for verification checklist.
 * Interactions (likes) count towards the interactions5 requirement.
 * Tracks unique users interacted with.
 */
export const onInteractionCreated = functions.firestore
  .document('interactions/{interactionId}')
  .onCreate(async (snap, context) => {
    const interactionId = context.params.interactionId;
    const interactionData = snap.data();
    const userCPId = interactionData?.userCPId;
    const targetId = interactionData?.targetId;
    const targetType = interactionData?.targetType; // 'comment' or 'post'
    const type = interactionData?.type;

    // Only track 'like' interactions
    if (type !== 'like') {
      console.log(`ℹ️ Interaction ${interactionId} is not a 'like', skipping`);
      return;
    }

    if (!userCPId) {
      console.log(`⚠️ Interaction ${interactionId} has no userCPId`);
      return;
    }

    // Convert Community Profile ID to User UID
    const userId = await getUserIdFromCPIdCached(userCPId);
    if (!userId) {
      console.log(`⚠️ Could not find user for CP ID: ${userCPId}`);
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

    // Skip if interactions5 already completed
    if (verification.checklist.interactions5.completed) {
      console.log(`ℹ️ User ${userId} has already completed interactions5`);
      return;
    }

    // Check if this interaction was already counted
    const alreadyCounted = await isActionAlreadyCounted(userId, 'like', interactionId);
    if (alreadyCounted) {
      console.log(`ℹ️ Interaction ${interactionId} already counted for user ${userId}`);
      return;
    }

    // Get the target document to determine the author (to track unique interactions)
    let targetUserCPId: string | null = null;
    if (targetId && targetType) {
      try {
        const collectionName = targetType === 'comment' ? 'comments' : 'forumPosts';
        const targetDoc = await db.collection(collectionName).doc(targetId).get();
        if (targetDoc.exists) {
          targetUserCPId = targetDoc.data()?.authorCPId || null;
        }
      } catch (error) {
        console.log(`⚠️ Error fetching ${targetType} ${targetId}:`, error);
      }
    }

    // Increment the counter
    const currentCount = verification.checklist.interactions5.current || 0;
    const newCount = currentCount + 1;

    // Update unique users array
    const uniqueUsers = verification.checklist.interactions5.uniqueUsers || [];
    if (targetUserCPId && !uniqueUsers.includes(targetUserCPId)) {
      uniqueUsers.push(targetUserCPId);
    }

    // Check if we've reached the requirement
    const completed = newCount >= 5;

    // Update the checklist item
    const updateData: any = {
      'checklist.interactions5.current': newCount,
      'checklist.interactions5.uniqueUsers': uniqueUsers,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (completed) {
      updateData['checklist.interactions5.completed'] = true;
      updateData['checklist.interactions5.completedAt'] = admin.firestore.FieldValue.serverTimestamp();
    }

    await verificationRef.update(updateData);

    // Mark this action as counted
    await markActionAsCounted(userId, 'like', interactionId);

    console.log(`✅ Like tracked for user ${userId}: ${newCount}/5 interactions`);

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

