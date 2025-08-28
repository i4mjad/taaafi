import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';
import * as sharp from 'sharp';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

const storage = new Storage();

/**
 * Cloud Function: generateImageThumbnails
 * 
 * Trigger: on finalize for images/{postId}/{attachmentId}/original.*
 * 
 * Purpose: Generate thumbnails for uploaded images and update attachment metadata.
 * Uses sharp for image processing with idempotent behavior.
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
      console.log(`[THUMBNAIL] Processing image: ${filePath} (post: ${postId}, attachment: ${attachmentId})`);
      
      // Check if thumbnail already exists (idempotency)
      const thumbPath = `images/${postId}/${attachmentId}/thumb.jpg`;
      const [thumbExists] = await bucket.file(thumbPath).exists();
      
      if (thumbExists) {
        console.log(`[THUMBNAIL] Thumbnail already exists: ${thumbPath}`);
        return;
      }
      
      // Download original image
      const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
      const thumbFilePath = path.join(os.tmpdir(), 'thumb.jpg');
      
      await bucket.file(filePath).download({ destination: tempFilePath });
      console.log(`[THUMBNAIL] Downloaded original to: ${tempFilePath}`);
      
      // Generate thumbnail using sharp
      const THUMB_EDGE_PX = 320;
      const imageBuffer = await sharp(tempFilePath)
        .resize(THUMB_EDGE_PX, THUMB_EDGE_PX, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .jpeg({ quality: 80 })
        .toBuffer();
      
      // Get image dimensions
      const metadata = await sharp(tempFilePath).metadata();
      const originalWidth = metadata.width || 0;
      const originalHeight = metadata.height || 0;
      
      // Upload thumbnail
      await bucket.file(thumbPath).save(imageBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            originalFile: filePath,
            generatedAt: new Date().toISOString(),
          }
        }
      });
      
      console.log(`[THUMBNAIL] Generated thumbnail: ${thumbPath}`);
      
      // Update attachment document with metadata
      const db = admin.firestore();
      const attachmentRef = db
        .collection('forumPosts')
        .doc(postId)
        .collection('attachments')
        .doc(attachmentId);
      
      await attachmentRef.update({
        thumbPath: thumbPath,
        w: originalWidth,
        h: originalHeight,
        mime: contentType,
        size: parseInt(object.size || '0', 10),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`[THUMBNAIL] Updated attachment metadata for: ${attachmentId}`);
      
      // Clean up temp files
      try {
        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(thumbFilePath);
      } catch (cleanupError) {
        console.log(`[THUMBNAIL] Cleanup warning: ${cleanupError}`);
      }
      
    } catch (error) {
      console.error(`[THUMBNAIL] Error processing ${filePath}:`, error);
      throw error;
    }
  });
