import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: finalizePostIfComplete
 * 
 * Trigger: on create/update of forumPosts/{postId}/attachments/* OR forumPosts/{postId}
 * 
 * Purpose: Automatically finalize a post when the attachment count matches
 * the expected count. This provides a reliable multi-step creation flow.
 */

// Trigger on attachment changes
export const finalizePostOnAttachmentChange = functions
  .region('us-central1')
  .firestore
  .document('forumPosts/{postId}/attachments/{attachmentId}')
  .onCreate(async (snap, context) => {
    const { postId } = context.params;
    await checkAndFinalizePost(postId);
  });

// Trigger on post changes (when expectedAttachmentsCount is set)
export const finalizePostOnPostUpdate = functions
  .region('us-central1')
  .firestore
  .document('forumPosts/{postId}')
  .onUpdate(async (change, context) => {
    const { postId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    
    // Only check if expectedAttachmentsCount changed
    if (before?.expectedAttachmentsCount !== after?.expectedAttachmentsCount) {
      await checkAndFinalizePost(postId);
    }
  });

async function checkAndFinalizePost(postId: string): Promise<void> {
  const db = admin.firestore();
  
  try {
    console.log(`[FINALIZE] Checking if post ${postId} should be finalized`);
    
    // Get post document
    const postDoc = await db.collection('forumPosts').doc(postId).get();
    
    if (!postDoc.exists) {
      console.log(`[FINALIZE] Post ${postId} not found`);
      return;
    }
    
    const postData = postDoc.data()!;
    
    // Check if already finalized
    if (postData.pendingAttachments === false) {
      console.log(`[FINALIZE] Post ${postId} already finalized`);
      return;
    }
    
    // Get current attachment count
    const attachmentsSnap = await db
      .collection('forumPosts')
      .doc(postId)
      .collection('attachments')
      .where('status', '==', 'active')
      .get();
    
    const currentCount = attachmentsSnap.docs.length;
    const expectedCount = postData.expectedAttachmentsCount || 0;
    
    console.log(`[FINALIZE] Post ${postId}: current=${currentCount}, expected=${expectedCount}`);
    
    // Finalize if counts match
    if (currentCount === expectedCount) {
      await db.collection('forumPosts').doc(postId).update({
        pendingAttachments: false,
        attachmentsFinalizedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`[FINALIZE] Post ${postId} finalized successfully`);
    } else {
      console.log(`[FINALIZE] Post ${postId} not ready for finalization`);
    }
    
  } catch (error) {
    console.error(`[FINALIZE] Error finalizing post ${postId}:`, error);
    throw error;
  }
}
