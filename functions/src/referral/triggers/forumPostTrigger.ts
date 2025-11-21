// functions/src/referral/triggers/forumPostTrigger.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUserIdFromCPIdCached } from '../helpers/userHelper';
import { isActionAlreadyCounted, markActionAsCounted } from '../helpers/actionTrackingHelper';
import { handleVerificationCompletion } from '../handlers/verificationHandler';
import { updateFraudScore } from '../fraud/fraudScoreCalculator';
import { ReferralVerification } from '../types/referral.types';

/**
 * Firestore trigger that tracks forum post creation for verification checklist.
 * Increments the forumPosts3 counter and marks as completed when 3 posts are reached.
 */
export const onForumPostCreated = functions.firestore
  .document('forumPosts/{postId}')
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const postData = snap.data();
    const authorCPId = postData?.authorCPId;

    if (!authorCPId) {
      console.log(`⚠️ Forum post ${postId} has no authorCPId`);
      return;
    }

    // Convert Community Profile ID to User UID
    const userId = await getUserIdFromCPIdCached(authorCPId);
    if (!userId) {
      console.log(`⚠️ Could not find user for CP ID: ${authorCPId}`);
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

    // Skip if forumPosts3 already completed
    if (verification.checklist.forumPosts3.completed) {
      console.log(`ℹ️ User ${userId} has already completed forumPosts3`);
      return;
    }

    // Check if this post was already counted
    const alreadyCounted = await isActionAlreadyCounted(userId, 'forumPost', postId);
    if (alreadyCounted) {
      console.log(`ℹ️ Forum post ${postId} already counted for user ${userId}`);
      return;
    }

    // Increment the counter
    const currentCount = verification.checklist.forumPosts3.current || 0;
    const newCount = currentCount + 1;

    // Check if we've reached the requirement
    const completed = newCount >= 3;

    // Update the checklist item
    const updateData: any = {
      'checklist.forumPosts3.current': newCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (completed) {
      updateData['checklist.forumPosts3.completed'] = true;
      updateData['checklist.forumPosts3.completedAt'] = admin.firestore.FieldValue.serverTimestamp();
    }

    await verificationRef.update(updateData);

    // Mark this action as counted
    await markActionAsCounted(userId, 'forumPost', postId);

    console.log(`✅ Forum post tracked for user ${userId}: ${newCount}/3 posts`);

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

