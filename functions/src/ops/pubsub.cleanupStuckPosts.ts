import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: cleanupStuckPosts
 * 
 * Schedule: every 6 hours
 * 
 * Purpose: Clean up posts that are stuck in pendingAttachments=true state
 * due to client crashes or network issues. Sets expectedAttachmentsCount
 * to current attachmentCount and triggers finalization.
 */
export const cleanupStuckPosts = functions
  .region('us-central1')
  .pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    
    try {
      console.log('[CLEANUP_STUCK] Starting stuck posts cleanup job');
      
      // Find posts that are stuck in pending state for more than 30 minutes
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
      
      const stuckPostsSnap = await db
        .collection('forumPosts')
        .where('pendingAttachments', '==', true)
        .where('updatedAt', '<', admin.firestore.Timestamp.fromDate(thirtyMinutesAgo))
        .limit(100) // Process in batches
        .get();
      
      if (stuckPostsSnap.empty) {
        console.log('[CLEANUP_STUCK] No stuck posts found');
        return;
      }
      
      console.log(`[CLEANUP_STUCK] Found ${stuckPostsSnap.docs.length} stuck posts`);
      
      const batch = db.batch();
      let processedCount = 0;
      
      for (const postDoc of stuckPostsSnap.docs) {
        const postId = postDoc.id;
        const postData = postDoc.data();
        
        try {
          // Count current active attachments
          const attachmentsSnap = await db
            .collection('forumPosts')
            .doc(postId)
            .collection('attachments')
            .where('status', '==', 'active')
            .get();
          
          const currentAttachmentCount = attachmentsSnap.docs.length;
          
          console.log(`[CLEANUP_STUCK] Post ${postId}: expected=${postData.expectedAttachmentsCount}, current=${currentAttachmentCount}`);
          
          // Update expected count to match current count and finalize
          batch.update(postDoc.ref, {
            expectedAttachmentsCount: currentAttachmentCount,
            pendingAttachments: false,
            attachmentsFinalizedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          processedCount++;
          
        } catch (error) {
          console.error(`[CLEANUP_STUCK] Error processing post ${postId}:`, error);
          // Continue with other posts
        }
      }
      
      if (processedCount > 0) {
        await batch.commit();
        console.log(`[CLEANUP_STUCK] Fixed ${processedCount} stuck posts`);
      } else {
        console.log('[CLEANUP_STUCK] No posts needed fixing');
      }
      
    } catch (error) {
      console.error('[CLEANUP_STUCK] Error in cleanup job:', error);
      throw error;
    }
  });
