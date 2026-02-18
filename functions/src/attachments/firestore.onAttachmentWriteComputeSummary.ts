const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Cloud Function: onAttachmentWriteComputeSummary
 * 
 * Trigger: on create/update/delete of forumPosts/{postId}/attachments/{attachmentId}
 * 
 * Purpose: Recompute attachment summary fields on the post document whenever
 * an attachment is created, updated, or deleted. This keeps the post document
 * lean while maintaining fast list rendering.
 */
exports.onAttachmentWriteComputeSummary = functions
  .region('us-central1')
  .firestore
  .document('forumPosts/{postId}/attachments/{attachmentId}')
  .onWrite(async (change, context) => {
    const { postId } = context.params;
    const db = admin.firestore();
    
    try {
      console.log(`[ATTACHMENT_SUMMARY] Processing attachment change for post ${postId}`);
      
      // Load all active attachments for this post (lightweight fields only)
      const attachmentsSnap = await db
        .collection('forumPosts')
        .doc(postId)
        .collection('attachments')
        .where('status', '==', 'active')
        .get();
      
      // Compute summary data
      const attachmentsSummaryById: Record<string, any> = {};
      const attachmentsOrder: string[] = [];
      const attachmentTypes: string[] = [];
      let attachmentsPreview: string | null = null;
      
      attachmentsSnap.docs.forEach((doc, index) => {
        const data = doc.data();
        const attachmentId = doc.id;
        
        // Add to order array
        attachmentsOrder.push(attachmentId);
        
        // Add type if not already present
        if (!attachmentTypes.includes(data.type)) {
          attachmentTypes.push(data.type);
        }
        
        // Create summary entry based on type
        let summaryEntry: any = {
          type: data.type,
        };
        
        switch (data.type) {
          case 'image':
            summaryEntry = {
              type: 'image',
              thumbPath: data.thumbPath || null,
              w: data.w || 0,
              h: data.h || 0,
            };
            // Use first image as preview
            if (index === 0 && data.thumbPath) {
              attachmentsPreview = data.thumbPath;
            }
            break;
            
          case 'poll':
            summaryEntry = {
              type: 'poll',
              options: (data.options || []).length,
              isClosed: data.isClosed || false,
            };
            break;
            
          case 'group_invite':
            summaryEntry = {
              type: 'group_invite',
            };
            break;
        }
        
        attachmentsSummaryById[attachmentId] = summaryEntry;
      });
      
      // Update post document with computed summary
      const updateData = {
        attachmentsSummaryById,
        attachmentsOrder,
        attachmentTypes,
        hasAttachments: attachmentsSnap.docs.length > 0,
        attachmentCount: attachmentsSnap.docs.length,
        attachmentsPreview,
        attachmentsComputedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      await db.collection('forumPosts').doc(postId).update(updateData);
      
      console.log(`[ATTACHMENT_SUMMARY] Updated summary for post ${postId}: ${attachmentsSnap.docs.length} attachments`);
      
    } catch (error) {
      console.error(`[ATTACHMENT_SUMMARY] Error computing summary for post ${postId}:`, error);
      throw error;
    }
  });
