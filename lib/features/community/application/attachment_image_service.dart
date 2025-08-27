import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/community/data/models/post_attachment_data.dart';

final attachmentImageServiceProvider = Provider<AttachmentImageService>((ref) {
  return AttachmentImageService(ref);
});

class AttachmentImageService {
  final Ref ref;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  AttachmentImageService(this.ref);

  /// Pick and process multiple images for post attachments
  Future<List<ImageItem>> pickImages({
    int maxImages = 4,
    String source = 'gallery', // 'gallery' or 'camera'
  }) async {
    try {
      List<XFile> selectedImages = [];
      
      if (source == 'camera') {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );
        if (image != null) selectedImages.add(image);
      } else {
        try {
          // Try multi-image picker first
          final List<XFile> images = await _picker.pickMultiImage(
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 90,
          );
          selectedImages = images.take(maxImages).toList();
        } catch (e) {
          // Fallback to single image picker on iOS issues
          ref.read(errorLoggerProvider).logException(e, StackTrace.current);
          
          // Try single image picker as fallback
          try {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 2048,
              maxHeight: 2048,
              imageQuality: 90,
            );
            if (image != null) selectedImages.add(image);
          } catch (fallbackError) {
            ref.read(errorLoggerProvider).logException(fallbackError, StackTrace.current);
            throw Exception('Failed to pick images: Both multi and single image picker failed');
          }
        }
      }
      
      if (selectedImages.isEmpty) return [];
      
      final List<ImageItem> processedImages = [];
      
      for (int i = 0; i < selectedImages.length; i++) {
        final processedImage = await _processImage(selectedImages[i], i);
        if (processedImage != null) {
          processedImages.add(processedImage);
        }
      }
      
      return processedImages;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return [];
    }
  }

  /// Process individual image: compress, generate thumbnail, validate
  Future<ImageItem?> _processImage(XFile image, int index) async {
    try {
      final File imageFile = File(image.path);
      final int fileSize = await imageFile.length();
      
      // Validate file size (5MB max)
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
      }
      
      // Read and decode image
      final Uint8List originalBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(originalBytes);
      
      if (originalImage == null) {
        throw Exception('Unable to decode image');
      }
      
      // Compress main image to max 512px dimension
      final img.Image compressedImage = _resizeImage(originalImage, 512);
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(compressedImage, quality: 85),
      );
      
      // Generate thumbnail (72px for list view)
      final img.Image thumbnailImage = _resizeImage(originalImage, 72);
      final Uint8List thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnailImage, quality: 75),
      );
      
      // Save processed files temporarily
      final String tempDir = imageFile.parent.path;
      final String baseName = 'processed_${DateTime.now().millisecondsSinceEpoch}_$index';
      
      final File compressedFile = File('$tempDir/$baseName.jpg');
      final File thumbnailFile = File('$tempDir/${baseName}_thumb.jpg');
      
      await compressedFile.writeAsBytes(compressedBytes);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      return ImageItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$index',
        localPath: compressedFile.path,
        thumbnailPath: thumbnailFile.path,
        fileName: '$baseName.jpg',
        width: compressedImage.width,
        height: compressedImage.height,
        sizeBytes: compressedBytes.length,
      );
      
    } catch (e) {
      // Log error but continue with other images
      ref.read(errorLoggerProvider).logException(e, StackTrace.current);
      return null;
    }
  }

  /// Upload processed images to Firebase Storage
  Future<List<UploadedImageData>> uploadImages({
    required String postId,
    required List<ImageItem> images,
    required Function(int current, int total, String fileName) onProgress,
  }) async {
    final List<UploadedImageData> uploadedImages = [];
    
    for (int i = 0; i < images.length; i++) {
      final ImageItem image = images[i];
      onProgress(i + 1, images.length, image.fileName ?? 'image.jpg');
      
      try {
        final uploadedImage = await _uploadSingleImage(postId, image);
        uploadedImages.add(uploadedImage);
      } catch (e) {
        ref.read(errorLoggerProvider).logException(e, StackTrace.current);
        // Continue with other images even if one fails
        continue;
      }
    }
    
    return uploadedImages;
  }

  /// Upload single image and thumbnail to Firebase Storage
  Future<UploadedImageData> _uploadSingleImage(String postId, ImageItem image) async {
    final DateTime timestamp = DateTime.now();
    final String timeStr = timestamp.millisecondsSinceEpoch.toString();
    final String randomStr = (timestamp.microsecond % 1000).toString().padLeft(3, '0');
    
    // Create storage paths
    final String imagePath = 'community_posts/$postId/images/${timeStr}_$randomStr.jpg';
    final String thumbnailPath = 'community_posts/$postId/thumbnails/${timeStr}_$randomStr.jpg';
    
    // Upload main image
    final Reference imageRef = _storage.ref().child(imagePath);
    final UploadTask imageUploadTask = imageRef.putFile(File(image.localPath));
    final TaskSnapshot imageSnapshot = await imageUploadTask;
    final String imageDownloadUrl = await imageSnapshot.ref.getDownloadURL();
    
    // Upload thumbnail
    final Reference thumbnailRef = _storage.ref().child(thumbnailPath);
    final UploadTask thumbnailUploadTask = thumbnailRef.putFile(File(image.thumbnailPath!));
    final TaskSnapshot thumbnailSnapshot = await thumbnailUploadTask;
    final String thumbnailDownloadUrl = await thumbnailSnapshot.ref.getDownloadURL();
    
    // Clean up temporary files
    try {
      await File(image.localPath).delete();
      if (image.thumbnailPath != null) {
        await File(image.thumbnailPath!).delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
    
    return UploadedImageData(
      id: image.id,
      storagePath: imagePath,
      downloadUrl: imageDownloadUrl,
      thumbnailUrl: thumbnailDownloadUrl,
      width: image.width ?? 512,
      height: image.height ?? 512,
      sizeBytes: image.sizeBytes ?? 0,
      contentHash: _generateContentHash(imageDownloadUrl),
    );
  }

  /// Resize image maintaining aspect ratio
  img.Image _resizeImage(img.Image image, int maxDimension) {
    int width = image.width;
    int height = image.height;
    
    if (width <= maxDimension && height <= maxDimension) {
      return image;
    }
    
    if (width > height) {
      height = (height * maxDimension / width).round();
      width = maxDimension;
    } else {
      width = (width * maxDimension / height).round();
      height = maxDimension;
    }
    
    return img.copyResize(image, width: width, height: height);
  }

  /// Generate simple content hash for image
  String _generateContentHash(String url) {
    // Simple hash based on URL and timestamp
    // In production, you might want to generate actual file hash
    return 'hash_${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}';
  }

  /// Clean up temporary files (call when attachment creation fails)
  Future<void> cleanupTempFiles(List<ImageItem> images) async {
    for (final image in images) {
      try {
        await File(image.localPath).delete();
        if (image.thumbnailPath != null) {
          await File(image.thumbnailPath!).delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
}

/// Data class for uploaded image with Firebase URLs
class UploadedImageData {
  final String id;
  final String storagePath;
  final String downloadUrl;
  final String thumbnailUrl;
  final int width;
  final int height;
  final int sizeBytes;
  final String contentHash;

  const UploadedImageData({
    required this.id,
    required this.storagePath,
    required this.downloadUrl,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.contentHash,
  });
}
