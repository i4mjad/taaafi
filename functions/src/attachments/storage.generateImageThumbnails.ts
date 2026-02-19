import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';
import sharp from 'sharp';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

const storage = new Storage();

/**
 * Cloud Function: updateImageMetadata
 * 
 * Trigger: on finalize for images/{postId}/{attachmentId}/original.*
 * 
 * Purpose: Update attachment metadata for uploaded images (NO thumbnail generation for 100% quality).
 * Uses sharp only for metadata extraction.
 */
export const generateImageThumbnails = functions
  .region('us-central1')
  .storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    
    // Only process images in the correct path structure
    if (!filePath || !filePath.startsWith('images/') || !contentType?.startsWith('image/')) {
      console.log(`[THUMBNAIL] Skipping non-image file: ${filePath}`);
      return;
    }
    
    // Parse path: images/{postId}/{attachmentId}/original.{ext}
    const pathParts = filePath.split('/');
    if (pathParts.length !== 4 || pathParts[3] !== `original.${path.extname(filePath).slice(1)}`) {
      console.log(`[THUMBNAIL] Skipping file with wrong path structure: ${filePath}`);
      return;
    }
    
    const [, postId, attachmentId, filename] = pathParts;
    const bucketName = object.bucket;
    const bucket = storage.bucket(bucketName);
    
    try {
      console.log(`[METADATA] Processing image metadata: ${filePath} (post: ${postId}, attachment: ${attachmentId})`);
      
      // Check if metadata already processed (idempotency)
      const db = admin.firestore();
      const attachmentRef = db
        .collection('forumPosts')
        .doc(postId)
        .collection('attachments')
        .doc(attachmentId);
      
      const attachmentDoc = await attachmentRef.get();
      if (attachmentDoc.exists && attachmentDoc.data()?.w) {
        console.log(`[METADATA] Metadata already processed for: ${attachmentId}`);
        return;
      }
      
      // Download original image for metadata extraction only
      const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
      
      await bucket.file(filePath).download({ destination: tempFilePath });
      console.log(`[METADATA] Downloaded original for metadata: ${tempFilePath}`);
      
      // Get image dimensions (NO thumbnail generation for 100% quality)
      const metadata = await sharp(tempFilePath).metadata();
      const originalWidth = metadata.width || 0;
      const originalHeight = metadata.height || 0;
      
      // Update attachment document with metadata only
      await attachmentRef.update({
        w: originalWidth,
        h: originalHeight,
        mime: contentType,
        size: parseInt(object.size || '0', 10),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`[METADATA] Updated attachment metadata for: ${attachmentId} (${originalWidth}x${originalHeight})`);
      
      // Clean up temp file
      try {
        fs.unlinkSync(tempFilePath);
      } catch (cleanupError) {
        console.log(`[METADATA] Cleanup warning: ${cleanupError}`);
      }
      
    } catch (error) {
      console.error(`[METADATA] Error processing ${filePath}:`, error);
      throw error;
    }
  });
