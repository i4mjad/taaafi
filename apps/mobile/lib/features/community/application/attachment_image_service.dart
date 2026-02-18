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
        );
        if (image != null) selectedImages.add(image);
      } else {
        try {
          // Try multi-image picker first
          final List<XFile> images = await _picker.pickMultiImage(
            requestFullMetadata: false,
          );
          selectedImages = images.take(maxImages).toList();
        } catch (e) {
          // Fallback to single image picker on iOS issues
          ref.read(errorLoggerProvider).logException(e, StackTrace.current);

          // Try single image picker as fallback
          try {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
              requestFullMetadata: false,
            );
            if (image != null) selectedImages.add(image);
          } catch (fallbackError) {
            ref
                .read(errorLoggerProvider)
                .logException(fallbackError, StackTrace.current);
            throw Exception(
                'Failed to pick images: Both multi and single image picker failed');
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

  /// Process individual image: NO compression, 100% original quality
  Future<ImageItem?> _processImage(XFile image, int index) async {
    try {
      final File imageFile = File(image.path);
      final int fileSize = await imageFile.length();

      // Validate file size (increase to 20MB for high quality images)
      if (fileSize > 20 * 1024 * 1024) {
        throw Exception(
            'Image too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
      }

      // Use 100% original image - NO processing at all
      final Uint8List originalBytes = await imageFile.readAsBytes();

      // Get basic metadata without processing
      final img.Image? originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Unable to decode image');
      }

      // Save original file directly - NO thumbnail generation
      final String tempDir = imageFile.parent.path;
      final String baseName =
          'original_${DateTime.now().millisecondsSinceEpoch}_$index';

      // Keep original file extension
      final String originalExtension = image.path.split('.').last.toLowerCase();
      final File originalFile = File('$tempDir/$baseName.$originalExtension');

      await originalFile.writeAsBytes(originalBytes); // 100% original quality

      return ImageItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$index',
        localPath: originalFile.path,
        thumbnailPath: null, // No thumbnail - use original for everything
        fileName: '$baseName.$originalExtension',
        width: originalImage.width,
        height: originalImage.height,
        sizeBytes: originalBytes.length,
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
  Future<UploadedImageData> _uploadSingleImage(
      String postId, ImageItem image) async {
    final DateTime timestamp = DateTime.now();
    final String timeStr = timestamp.millisecondsSinceEpoch.toString();
    final String randomStr =
        (timestamp.microsecond % 1000).toString().padLeft(3, '0');

    // Create stable attachment ID and storage paths (new structure)
    final String attachmentId = '${postId}-${timeStr}${randomStr}';

    // Keep original file extension for 100% quality
    final String fileExtension = image.fileName?.split('.').last ?? 'jpg';
    final String imagePath =
        'images/$postId/$attachmentId/original.$fileExtension';

    // Upload main image (100% original quality)
    final Reference imageRef = _storage.ref().child(imagePath);
    final UploadTask imageUploadTask = imageRef.putFile(File(image.localPath));
    final TaskSnapshot imageSnapshot = await imageUploadTask;
    final String imageDownloadUrl = await imageSnapshot.ref.getDownloadURL();

    // Use same URL for thumbnail since we're not generating thumbnails
    final String thumbnailDownloadUrl = imageDownloadUrl;

    // Clean up temporary files
    try {
      await File(image.localPath).delete();
      // No separate thumbnail file to delete since we use original for everything
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
        // No separate thumbnail files to delete since we use original for everything
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
