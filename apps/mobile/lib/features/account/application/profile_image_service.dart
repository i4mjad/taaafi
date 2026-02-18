import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService(ref);
});

class ProfileImageService {
  final Ref ref;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileImageService(this.ref);

  /// Shows image source selection dialog and handles the complete flow
  Future<void> changeProfileImage(BuildContext context) async {
    try {
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      await _uploadAndUpdateProfileImage(context, image);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'Failed to update profile image');
    }
  }

  /// Shows modal bottom sheet to choose between camera and gallery
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    final theme = AppTheme.of(context);

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              verticalSpace(Spacing.points16),

              // Title
              Text(
                AppLocalizations.of(context).translate('select-image-source'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              verticalSpace(Spacing.points16),

              // Camera option
              ListTile(
                leading: Icon(
                  LucideIcons.camera,
                  color: theme.primary[600],
                ),
                title: Text(
                  AppLocalizations.of(context).translate('camera'),
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),

              // Gallery option
              ListTile(
                leading: Icon(
                  LucideIcons.image,
                  color: theme.primary[600],
                ),
                title: Text(
                  AppLocalizations.of(context).translate('gallery'),
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),

              verticalSpace(Spacing.points8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: TextStyles.body.copyWith(color: theme.grey[600]),
                  ),
                ),
              ),

              verticalSpace(Spacing.points16),
            ],
          ),
        );
      },
    );
  }

  /// Uploads image to Firebase Storage and updates user profile
  Future<void> _uploadAndUpdateProfileImage(
      BuildContext context, XFile image) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        getErrorSnackBar(context, 'User not authenticated');
        return;
      }

      // Show loading indicator
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          final theme = AppTheme.of(context);
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                verticalSpace(Spacing.points16),
                const CircularProgressIndicator(),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context).translate('uploading-image'),
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
                verticalSpace(Spacing.points24),
              ],
            ),
          );
        },
      );

      // Create storage reference
      final String fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          _storage.ref().child('profile_images/$fileName');

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile
      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      getSuccessSnackBar(context, 'profile-image-updated-successfully');

      // Refresh user data
      ref.invalidate(userNotifierProvider);
    } catch (e, stackTrace) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'Failed to upload image');
      rethrow;
    }
  }

  /// Removes the current profile image
  Future<void> removeProfileImage(BuildContext context) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        getErrorSnackBar(context, 'User not authenticated');
        return;
      }

      await user.updatePhotoURL(null);
      await user.reload();

      // Refresh user data
      ref.invalidate(userNotifierProvider);

      getSuccessSnackBar(context, 'profile-image-removed-successfully');
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'Failed to remove profile image');
    }
  }
}
