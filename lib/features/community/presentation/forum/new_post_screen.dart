import 'dart:io';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/features/community/data/exceptions/forum_exceptions.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/forum/anonymity_toggle_modal.dart';
import 'package:reboot_app_3/features/community/presentation/forum/validation_info_modal.dart';
import 'package:reboot_app_3/features/community/presentation/forum/validation_info_modal_preferences.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/account/data/app_features_config.dart';
import 'package:reboot_app_3/features/community/data/models/post_attachment_data.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';
import 'package:reboot_app_3/features/community/application/attachment_image_service.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart' as shared;
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';

/// Screen for creating a new forum post
///
/// This screen provides a clean, user-friendly interface for creating new forum posts.
/// It follows SOLID principles with proper separation of concerns and uses the ForumService
/// for business logic. Error handling is implemented with consistent snackbar messages.
///
/// Features:
/// - Real-time validation feedback
/// - Category selection
/// - Anonymity toggle
/// - Character limits with visual feedback
/// - Proper error handling with localized messages
/// - Loading states
/// - Form reset functionality
class NewPostScreen extends ConsumerStatefulWidget {
  /// Optional initial category ID to pre-select when the screen opens
  final String? initialCategoryId;

  const NewPostScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Focus nodes for better UX
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  // Form state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the title field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();

      // Set initial category if provided
      if (widget.initialCategoryId != null) {
        _setInitialCategory();
      }

      // Initialize anonymity state based on user's profile setting
      ref.read(currentCommunityProfileProvider).whenData((profile) {
        if (profile != null) {
          ref.read(anonymousPostProvider.notifier).state = profile.isAnonymous;
        }
      });

      // Show validation info modal on first visit
      _showValidationInfoModalIfNeeded();
    });
  }

  /// Sets the initial category based on the provided category ID
  Future<void> _setInitialCategory() async {
    try {
      // Wait for categories to load
      final categories = await ref.read(newPostCategoriesProvider.future);

      // Find the category with the matching ID
      final matchingCategory = categories.firstWhere(
        (category) => category.id == widget.initialCategoryId,
        orElse: () => const PostCategory(
          id: 'DFbm1WSnUyrOmtKZYWVb',
          name: 'General',
          nameAr: 'عام',
          iconName: 'chat',
          colorHex: '#6B7280',
          isActive: true,
          sortOrder: 7,
        ),
      );

      // Set the selected category in the provider
      if (mounted) {
        ref.read(selectedCategoryProvider.notifier).state = matchingCategory;
      }
    } catch (e) {
      // If there's an error, just continue with the default category
      print('Error setting initial category: $e');
    }
  }

  /// Shows the validation info modal if the user hasn't seen it before
  Future<void> _showValidationInfoModalIfNeeded() async {
    final hasSeenModal = ref.read(validationInfoModalProvider);
    if (!hasSeenModal) {
      // Add a small delay to ensure the screen is fully built
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showValidationInfoModal();
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// Checks if the form can be submitted
  bool get _canSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Watch providers for reactive UI updates
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isAnonymous = ref.watch(anonymousPostProvider);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    // Listen to post creation state for handling results
    ref.listen<AsyncValue<String?>>(postCreationProvider, (previous, next) {
      _handlePostCreationResult(next, localizations);
    });

    // Listen to categories loading and set default to general category if none selected
    ref.listen<AsyncValue<List<PostCategory>>>(newPostCategoriesProvider,
        (previous, next) {
      next.whenData((categories) {
        final currentSelected = ref.read(selectedCategoryProvider);
        if (currentSelected == null && categories.isNotEmpty) {
          // Find general category from Firestore and set as default
          PostCategory? generalCategory;
          try {
            generalCategory =
                categories.firstWhere((category) => category.id == 'general');
          } catch (e) {
            // If no general category found, use the first available category
            generalCategory = categories.first;
          }
          ref.read(selectedCategoryProvider.notifier).state = generalCategory;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background
      body: GestureDetector(
        onTap: () => _handleClose(), // Dismiss on background tap
        child: Container(
          color: Colors.transparent, // Transparent but still tappable
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
          ),
          child: GestureDetector(
            onTap:
                () {}, // Prevent background tap from bubbling through modal content
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Dismiss bar with tap gesture
                  GestureDetector(
                    onTap: () => _handleClose(),
                    child: _buildDismissBar(theme),
                  ),

                  // App bar content
                  _buildAppBarContent(theme, localizations),

                  // User profile header
                  _buildUserProfileHeader(theme, localizations,
                      currentProfileAsync.asData?.value, isAnonymous),

                  Divider(color: theme.grey[200], height: 1),

                  // Main content area
                  Expanded(
                    child: _buildContentArea(
                        theme, localizations, selectedCategory),
                  ),

                  // Bottom section with character counts
                  _buildBottomSection(theme, localizations),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the dismiss bar at the top of the modal
  Widget _buildDismissBar(CustomThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: theme.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// Builds the app bar content (replacing the old AppBar)
  Widget _buildAppBarContent(
      CustomThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Close button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () => _handleClose(),
              style: IconButton.styleFrom(
                foregroundColor: theme.grey[600],
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Center(
              child: Text(
                localizations.translate('new_thread'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Info icon for validation guidelines
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              onPressed: () => _showValidationInfoModal(),
              icon: Icon(Icons.info_outline, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: theme.grey[600],
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the post button with loading state
  Widget _buildPostButton(
      CustomThemeData theme, AppLocalizations localizations) {
    return Container(
      height: 36,
      child: TextButton(
        onPressed: _canSubmit ? _handleSubmit : null,
        style: TextButton.styleFrom(
          backgroundColor: _canSubmit ? theme.primary[500] : theme.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: Size.zero,
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 16,
                height: 16,
                child: Spinner(
                  valueColor: theme.grey[50],
                  strokeWidth: 2,
                ),
              )
            : Text(
                localizations.translate('post'),
                style: TextStyles.footnote.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Builds the user profile header section
  Widget _buildUserProfileHeader(
    CustomThemeData theme,
    AppLocalizations localizations,
    dynamic profile,
    bool isAnonymous,
  ) {
    if (profile != null) {
      return _buildProfileHeaderWithData(
          theme, localizations, profile, isAnonymous);
    }
    return _buildFallbackProfileHeader(theme, localizations, isAnonymous);
  }

  /// Builds profile header when user profile data is available
  Widget _buildProfileHeaderWithData(
    CustomThemeData theme,
    AppLocalizations localizations,
    dynamic profile,
    bool isAnonymous,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final userImageUrl = user?.photoURL;
    final displayName = profile.displayName;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primary[100],
            backgroundImage: isAnonymous || userImageUrl == null
                ? null
                : NetworkImage(userImageUrl),
            child: isAnonymous || userImageUrl == null
                ? Icon(
                    isAnonymous ? Icons.person_outline : Icons.person,
                    size: 20,
                    color: theme.primary[700],
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous
                      ? localizations.translate('community-anonymous')
                      : displayName ?? 'Community Member',
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isAnonymous
                      ? localizations.translate('anonymous-mode-reassurance')
                      : localizations
                          .translate('community-profile-visible-message'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Anonymity toggle button
          _buildAnonymityToggleButton(
              theme, localizations, profile, isAnonymous),
        ],
      ),
    );
  }

  /// Builds fallback profile header when profile data is not available
  Widget _buildFallbackProfileHeader(
    CustomThemeData theme,
    AppLocalizations localizations,
    bool isAnonymous,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primary[100],
            child: Text(
              'T',
              style: TextStyles.caption.copyWith(
                color: theme.primary[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ta3afi Community',
            style: TextStyles.body.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildSimpleAnonymityToggle(theme, localizations, isAnonymous),
        ],
      ),
    );
  }

  /// Builds the anonymity toggle button
  Widget _buildAnonymityToggleButton(
    CustomThemeData theme,
    AppLocalizations localizations,
    dynamic profile,
    bool isAnonymous,
  ) {
    return GestureDetector(
      onTap: () => _showAnonymityToggleModal(profile, isAnonymous),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAnonymous ? Icons.visibility : Icons.visibility_off_outlined,
              size: 16,
              color: theme.primary[600],
            ),
            const SizedBox(width: 6),
            Text(
              isAnonymous
                  ? localizations.translate('show-identity')
                  : localizations.translate('hide-identity'),
              style: TextStyles.caption.copyWith(
                color: theme.primary[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds simple anonymity toggle for fallback header
  Widget _buildSimpleAnonymityToggle(
    CustomThemeData theme,
    AppLocalizations localizations,
    bool isAnonymous,
  ) {
    return GestureDetector(
      onTap: () => _toggleAnonymity(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAnonymous ? theme.primary[100] : theme.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAnonymous ? theme.primary[300]! : theme.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 14,
              color: isAnonymous ? theme.primary[600] : theme.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              localizations.translate('post_anonymously'),
              style: TextStyles.caption.copyWith(
                color: isAnonymous ? theme.primary[600] : theme.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main content area with form fields
  Widget _buildContentArea(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostCategory? selectedCategory,
  ) {
    final attachmentState = ref.watch(postAttachmentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input field
          _buildTitleInput(theme, localizations),

          // Category selector
          _buildCategorySelector(theme, localizations, selectedCategory),

          verticalSpace(Spacing.points4),

          // Content input field
          _buildContentInput(theme, localizations),

          // Attachment previews (displayed below content input as requested)
          if (attachmentState.attachmentData != null) ...[
            verticalSpace(Spacing.points16),
            _buildDetailedAttachmentPreview(
                theme, localizations, attachmentState),
          ],

          verticalSpace(Spacing.points4),
        ],
      ),
    );
  }

  /// Builds the title input field
  Widget _buildTitleInput(
      CustomThemeData theme, AppLocalizations localizations) {
    final currentLength = _titleController.text.length;
    final maxLength = PostFormValidationConstants.maxTitleLength;
    final isNearLimit = currentLength > maxLength * 0.8;
    final isOverLimit = currentLength > maxLength;

    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      maxLines: null,
      maxLength: PostFormValidationConstants.maxTitleLength,
      style: TextStyles.h4.copyWith(
        color: theme.grey[900],
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: localizations.translate('post_title'),
        hintStyle: TextStyles.h4.copyWith(
          color: theme.grey[400],
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
        counterText: '$currentLength/$maxLength',
        counterStyle: TextStyles.caption.copyWith(
          color: isOverLimit
              ? theme.error[500]
              : isNearLimit
                  ? theme.warn[500]
                  : theme.grey[500],
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  /// Builds the category selector
  Widget _buildCategorySelector(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostCategory? selectedCategory,
  ) {
    return GestureDetector(
      onTap: () => _showCategorySelector(theme, localizations),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          color: selectedCategory != null
              ? selectedCategory.color.withValues(alpha: 0.1)
              : theme.grey[100],
          shape: SmoothRectangleBorder(
            side: BorderSide(
              color: selectedCategory != null
                  ? selectedCategory.color
                  : theme.grey[300]!,
            ),
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedCategory?.icon ?? Icons.local_offer_outlined,
              size: 16,
              color: selectedCategory != null
                  ? selectedCategory.color
                  : theme.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              selectedCategory
                      ?.getDisplayName(localizations.locale.languageCode) ??
                  localizations.translate('select_category'),
              style: TextStyles.caption.copyWith(
                color: selectedCategory != null
                    ? selectedCategory.color
                    : theme.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: selectedCategory != null
                  ? selectedCategory.color
                  : theme.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the content input field
  Widget _buildContentInput(
      CustomThemeData theme, AppLocalizations localizations) {
    final currentLength = _contentController.text.length;
    final maxLength = PostFormValidationConstants.maxContentLength;
    final isNearLimit = currentLength > maxLength * 0.8;
    final isOverLimit = currentLength > maxLength;

    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      maxLines: null,
      minLines: 8,
      maxLength: PostFormValidationConstants.maxContentLength,
      style: TextStyles.body.copyWith(
        color: theme.grey[900],
        fontSize: 16,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: localizations.translate('whats_on_your_mind'),
        hintStyle: TextStyles.body.copyWith(
          color: theme.grey[500],
          fontSize: 16,
        ),
        border: InputBorder.none,
        counterText: '$currentLength/$maxLength',
        counterStyle: TextStyles.caption.copyWith(
          color: isOverLimit
              ? theme.error[500]
              : isNearLimit
                  ? theme.warn[500]
                  : theme.grey[500],
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  /// Builds the bottom section with attachment icons
  Widget _buildBottomSection(
      CustomThemeData theme, AppLocalizations localizations) {
    final attachmentState = ref.watch(postAttachmentsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(color: theme.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Attachment action icons (left side)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentIcon(
                theme,
                LucideIcons.image,
                () => _handleAttachmentTap(AttachmentType.image),
                isSelected:
                    attachmentState.selectedType == AttachmentType.image,
              ),
              horizontalSpace(Spacing.points12),
              _buildAttachmentIcon(
                theme,
                LucideIcons.barChart3,
                () => _handleAttachmentTap(AttachmentType.poll),
                isSelected: attachmentState.selectedType == AttachmentType.poll,
              ),
            ],
          ),

          // Post button (right side)
          _buildPostButton(theme, localizations),
        ],
      ),
    );
  }

  /// Builds an attachment icon button
  Widget _buildAttachmentIcon(
      CustomThemeData theme, IconData icon, VoidCallback onTap,
      {bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: theme.primary[300]!) : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.primary[600] : theme.grey[600],
        ),
      ),
    );
  }

  /// Builds detailed attachment preview
  Widget _buildDetailedAttachmentPreview(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostAttachmentsState attachmentState,
  ) {
    switch (attachmentState.selectedType) {
      case AttachmentType.image:
        return _buildImagePreview(theme, localizations, attachmentState);
      case AttachmentType.poll:
        return _buildPollPreview(theme, localizations, attachmentState);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds image attachment preview with thumbnails
  Widget _buildImagePreview(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostAttachmentsState attachmentState,
  ) {
    final imageData = attachmentState.attachmentData as ImageAttachmentData?;
    if (imageData == null || imageData.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      // margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageData.images.length,
        itemBuilder: (context, index) {
          final image = imageData.images[index];

          return Container(
            margin: EdgeInsets.only(
              right: index == imageData.images.length - 1 ? 0 : 12,
            ),
            child: Stack(
              children: [
                // Image thumbnail
                GestureDetector(
                  onTap: () => _showImagePreview(image, imageData.images),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.grey[200],
                      image: image.localPath != null
                          ? DecorationImage(
                              image: FileImage(File(image.localPath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: image.localPath == null
                        ? Icon(
                            LucideIcons.image,
                            size: 40,
                            color: theme.grey[500],
                          )
                        : null,
                  ),
                ),
                // Delete button
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeImage(image.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.error[500]!.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds poll attachment preview
  Widget _buildPollPreview(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostAttachmentsState attachmentState,
  ) {
    final pollData = attachmentState.attachmentData as PollAttachmentData?;
    if (pollData == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _editPoll(pollData),
      child: WidgetsContainer(
        width: double.infinity, // Full width
        padding: const EdgeInsets.all(14),
        backgroundColor: theme.primary[50],
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary[200]!, width: 1),
        cornerSmoothing: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with poll icon and actions
            Row(
              children: [
                WidgetsContainer(
                  padding: const EdgeInsets.all(6),
                  backgroundColor: theme.primary[100],
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                  cornerSmoothing: 0.6,
                  child: Icon(
                    LucideIcons.barChart3,
                    size: 18,
                    color: theme.primary[600],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('poll'),
                        style: TextStyles.footnoteSelected.copyWith(
                          color: theme.primary[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                          height:
                              2), // Proper spacing between heading and description
                      Text(
                        '${pollData.options.length} ${localizations.translate(pollData.options.length > 1 ? 'poll-options' : 'poll-option')}${pollData.isMultiSelect ? ' • ${localizations.translate('poll-multi-select')}' : ''}',
                        style: TextStyles.caption.copyWith(
                          color: theme.primary[600],
                        ),
                        maxLines: null, // Allow text to wrap
                      ),
                    ],
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: () => _editPoll(pollData),
                  child: WidgetsContainer(
                    padding: const EdgeInsets.all(4),
                    backgroundColor: theme.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                    cornerSmoothing: 0.6,
                    child: Icon(
                      LucideIcons.pencil,
                      size: 14,
                      color: theme.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Clear button
                GestureDetector(
                  onTap: _clearAttachments,
                  child: WidgetsContainer(
                    padding: const EdgeInsets.all(4),
                    backgroundColor: theme.error[100],
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                    cornerSmoothing: 0.6,
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: theme.error[600],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Poll question section - more compact
            WidgetsContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              backgroundColor: theme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.grey[200]!, width: 1),
              cornerSmoothing: 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('poll-question'),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[500],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3), // Proper spacing
                  Text(
                    pollData.question.isNotEmpty
                        ? pollData.question
                        : localizations.translate('poll-question-placeholder'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Options preview section - more compact
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('poll-options-preview'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6), // Proper spacing
                ...pollData.options.take(3).map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: theme.primary[100],
                              shape: pollData.isMultiSelect
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: pollData.isMultiSelect
                                  ? BorderRadius.circular(3)
                                  : null,
                              border: Border.all(
                                color: theme.primary[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[700],
                                fontSize: 13,
                              ),
                              maxLines: null, // Allow text to wrap
                            ),
                          ),
                        ],
                      ),
                    )),
                if (pollData.options.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+${pollData.options.length - 3} ${localizations.translate('more-options')}',
                      style: TextStyles.caption.copyWith(
                        color: theme.primary[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            // Tap to edit hint - more compact
            const SizedBox(height: 10),
            WidgetsContainer(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              backgroundColor: theme.primary[50],
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
              cornerSmoothing: 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.edit3,
                    size: 12,
                    color: theme.primary[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    localizations.translate('tap-to-edit-poll'),
                    style: TextStyles.caption.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper methods for attachment management
  void _clearAttachments() {
    ref.read(postAttachmentsProvider.notifier).clearAttachments();
  }

  /// Handle attachment icon tap with Plus eligibility check
  void _handleAttachmentTap(AttachmentType attachmentType) {
    final hasActiveSubscription = ref.read(hasActiveSubscriptionProvider);

    if (!hasActiveSubscription) {
      // Show Plus subscription modal
      _showPlusSubscriptionModal();
      return;
    }

    // User has Plus access - proceed with attachment functionality
    switch (attachmentType) {
      case AttachmentType.image:
        _handleImageAttachment();
        break;
      case AttachmentType.poll:
        _handlePollAttachment();
        break;
      case AttachmentType.groupInvite:
        // Group invite functionality has been removed
        break;
    }
  }

  /// Show Plus subscription modal
  void _showPlusSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const TaaafiPlusSubscriptionScreen(),
    );
  }

  /// Attachment action handlers (for Plus users)
  void _handleImageAttachment() async {
    // Show loading modal first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.2,
          maxChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.of(context).backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Loading spinner
                      Spinner(
                        strokeWidth: 3,
                        valueColor: AppTheme.of(context).primary[600],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Check feature access
    final canAccess =
        await checkFeatureAccess(ref, AppFeaturesConfig.shareMedia);

    if (!context.mounted) return;

    // Close loading modal
    Navigator.of(context).pop();

    if (!canAccess) {
      // Show ban message
      await checkFeatureAccessAndShowBanSnackbar(
        context,
        ref,
        AppFeaturesConfig.shareMedia,
        customMessage:
            AppLocalizations.of(context).translate('media-sharing-restricted'),
      );
    } else {
      // Execute the image attachment logic
      try {
        final imageService = ref.read(attachmentImageServiceProvider);
        final images = await imageService.pickImages(maxImages: 4);

        if (images.isNotEmpty) {
          ref.read(postAttachmentsProvider.notifier).updateImages(images);
        }
      } catch (e) {
        getErrorSnackBar(context, 'Failed to select images');
      }
    }
  }

  /// Remove a single image by ID
  void _removeImage(String imageId) {
    print('Removing image: $imageId'); // Debug log
    ref.read(postAttachmentsProvider.notifier).removeImage(imageId);
  }

  /// Show fullscreen image preview
  void _showImagePreview(dynamic image, List<dynamic> allImages) {
    print('Opening image preview for image: ${image.id}'); // Debug log
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _ImagePreviewModal(
        image: image,
        allImages: allImages,
      ),
    );
  }

  void _handlePollAttachment() async {
    // Show loading modal first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.2,
          maxChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.of(context).backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Loading spinner
                      Spinner(
                        strokeWidth: 3,
                        valueColor: AppTheme.of(context).primary[600],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Check feature access
    final canAccess =
        await checkFeatureAccess(ref, AppFeaturesConfig.createPoll);

    if (!context.mounted) return;

    // Close loading modal
    Navigator.of(context).pop();

    if (!canAccess) {
      // Show ban message
      await checkFeatureAccessAndShowBanSnackbar(
        context,
        ref,
        AppFeaturesConfig.createPoll,
        customMessage:
            AppLocalizations.of(context).translate('poll-creation-restricted'),
      );
    } else {
      // Show the poll creation modal
      _showPollCreationModal();
    }
  }

  /// Shows poll creation modal
  void _showPollCreationModal({PollAttachmentData? existingPoll}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _PollCreationModal(
        existingPoll: existingPoll,
        onPollCreated: (pollData) {
          ref.read(postAttachmentsProvider.notifier).updatePoll(pollData);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Edit existing poll
  void _editPoll(PollAttachmentData pollData) {
    _showPollCreationModal(existingPoll: pollData);
  }

  /// Shows the category selector modal
  void _showCategorySelector(
      CustomThemeData theme, AppLocalizations localizations) {
    // Force refresh the categories provider to ensure fresh data
    ref.invalidate(newPostCategoriesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final categoriesAsync = ref.watch(newPostCategoriesProvider);
          return _buildCategorySelectorModal(
              theme, localizations, categoriesAsync);
        },
      ),
    );
  }

  /// Builds the category selector modal content
  Widget _buildCategorySelectorModal(
    CustomThemeData theme,
    AppLocalizations localizations,
    AsyncValue<List<PostCategory>> categoriesAsync,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            localizations.translate('select_category'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Categories content
          categoriesAsync.when(
            data: (categories) =>
                _buildCategoryList(theme, localizations, categories),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Spinner(),
              ),
            ),
            error: (error, stackTrace) =>
                _buildCategoryError(theme, localizations, error),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds the category list
  Widget _buildCategoryList(
    CustomThemeData theme,
    AppLocalizations localizations,
    List<PostCategory> categories,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((category) =>
              _buildCategoryOption(theme, localizations, category))
          .toList(),
    );
  }

  /// Builds a single category option
  Widget _buildCategoryOption(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostCategory category,
  ) {
    final displayName =
        category.getDisplayName(localizations.locale.languageCode);

    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: WidgetsContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: category.color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: category.color,
            ),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyles.caption.copyWith(
                color: category.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds category error display
  Widget _buildCategoryError(
      CustomThemeData theme, AppLocalizations localizations,
      [Object? error]) {
    return Text(
      localizations.translate('error_loading_categories'),
      style: TextStyles.caption.copyWith(color: theme.error[500]),
    );
  }

  /// Shows the anonymity toggle modal
  void _showAnonymityToggleModal(dynamic profile, bool currentAnonymousState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnonymityToggleModal(
        profile: profile,
        currentAnonymousState:
            ref.read(anonymousPostProvider), // Always use actual provider state
        onToggleComplete: (newAnonymityState) {
          ref.read(anonymousPostProvider.notifier).state = newAnonymityState;
          ref.refresh(currentCommunityProfileProvider);
        },
      ),
    );
  }

  /// Shows the validation info modal
  void _showValidationInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: ValidationInfoModal(
          onDismiss: () {
            Navigator.pop(context);
            // Mark as seen so it won't show automatically again
            ref.read(validationInfoModalProvider.notifier).markAsSeen();
          },
        ),
      ),
    );
  }

  /// Handles close button tap
  void _handleClose() {
    if (_hasUnsavedChanges()) {
      _showUnsavedChangesDialog();
    } else {
      context.pop();
    }
  }

  /// Checks if there are unsaved changes
  bool _hasUnsavedChanges() {
    return _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;
  }

  /// Shows unsaved changes modal bottom sheet
  void _showUnsavedChangesDialog() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              localizations.translate('unsaved_changes'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              localizations.translate('unsaved_changes_message'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: theme.grey[100],
                      foregroundColor: theme.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localizations.translate('cancel'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: theme.error[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localizations.translate('discard'),
                      style: TextStyles.footnote.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom padding for safe area
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Handles form submission with feature access check
  Future<void> _handleSubmit() async {
    print('🚀 [NewPostScreen] _handleSubmit called');

    if (!_canSubmit) {
      print('❌ [NewPostScreen] Cannot submit - form validation failed');
      return;
    }

    print('✅ [NewPostScreen] Form validation passed, starting submission...');

    // Show loader immediately so the user gets instant feedback
    setState(() => _isSubmitting = true);
    // Give the UI a chance to rebuild before heavy async work starts
    await Future.delayed(Duration.zero);

    // Double-check feature access before submitting
    final canAccess =
        await checkFeatureAccess(ref, AppFeaturesConfig.postCreation);
    if (!canAccess) {
      // Reset loader when access is denied
      setState(() => _isSubmitting = false);
      print('🚫 [NewPostScreen] Post creation feature access denied');
      getErrorSnackBar(
        context,
        'post-creation-restricted',
      );
      return;
    }

    print('✅ [NewPostScreen] Feature access granted, continuing submission...');

    try {
      // Create post data
      final postData = PostFormData(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: ref.read(selectedCategoryProvider)?.id,
      );

      print('📝 [NewPostScreen] Created PostFormData:');
      print('   - Title: "${postData.title}" (${postData.title.length} chars)');
      print(
          '   - Content: "${postData.content.substring(0, postData.content.length > 50 ? 50 : postData.content.length)}${postData.content.length > 50 ? '...' : ''}" (${postData.content.length} chars)');
      print('   - Category ID: ${postData.categoryId}');

      // Get attachment data if any
      final attachmentState = ref.read(postAttachmentsProvider);

      print(
          '📎 [NewPostScreen] Attachment state: ${attachmentState.selectedType}');
      if (attachmentState.attachmentData != null) {
        print(
            '   - Has attachment data: ${attachmentState.attachmentData.runtimeType}');
      }

      // Submit through the provider
      print('🔄 [NewPostScreen] Calling postCreationProvider.createPost...');
      await ref.read(postCreationProvider.notifier).createPost(
            postData,
            AppLocalizations.of(context),
            attachmentData: attachmentState,
          );
      print(
          '✅ [NewPostScreen] postCreationProvider.createPost completed successfully');
    } catch (e) {
      // Error handling is done in the listener
      print('❌ [NewPostScreen] Exception in _handleSubmit: $e');
      setState(() => _isSubmitting = false);
    }
  }

  /// Handles post creation results
  void _handlePostCreationResult(
      AsyncValue<String?> result, AppLocalizations localizations) {
    print(
        '📊 [NewPostScreen] _handlePostCreationResult called with result type: ${result.runtimeType}');

    result.when(
      data: (postId) {
        print('✅ [NewPostScreen] Post creation successful with ID: $postId');
        if (postId != null) {
          // Success - reset loading state, invalidate posts provider, show success message and navigate back
          setState(() => _isSubmitting = false);

          // Invalidate providers to refresh the posts list across all screens
          ref.invalidate(postsPaginationProvider);
          ref.invalidate(mainScreenPostsProvider(null));
          ref.invalidate(pinnedPostsPaginationProvider);
          ref.invalidate(newsPostsPaginationProvider);

          print(
              '🎉 [NewPostScreen] Showing success snackbar and navigating back');
          getSuccessSnackBar(context, 'post_created');
          _resetForm();
          context.pop();
        } else {
          print('⚠️ [NewPostScreen] Post creation returned null ID');
          setState(() => _isSubmitting = false);
        }
      },
      loading: () {
        print('⏳ [NewPostScreen] Post creation in loading state');
        // Loading state is handled by the submit button
      },
      error: (error, stackTrace) {
        print('❌ [NewPostScreen] Post creation error: $error');
        print('📋 [NewPostScreen] Stack trace: $stackTrace');
        setState(() => _isSubmitting = false);
        _handleError(error, localizations);
      },
    );
  }

  /// Handles errors with appropriate snackbar messages
  void _handleError(Object error, AppLocalizations localizations) {
    print('🔧 [NewPostScreen] _handleError called with error: $error');
    print('🔧 [NewPostScreen] Error type: ${error.runtimeType}');

    if (error is PostValidationException) {
      print(
          '📝 [NewPostScreen] PostValidationException - code: ${error.code}, message: ${error.message}');
      // Use the error code as translation key instead of the already translated message
      final translationKey = _getValidationErrorKey(error);
      print('🗣️ [NewPostScreen] Using translation key: $translationKey');
      getErrorSnackBar(context, translationKey);
    } else if (error is ForumAuthenticationException) {
      print('🔐 [NewPostScreen] ForumAuthenticationException detected');
      getErrorSnackBar(context, 'authentication_required');
    } else if (error is ForumPermissionException) {
      print('🚫 [NewPostScreen] ForumPermissionException detected');
      getErrorSnackBar(context, 'permission_denied');
    } else if (error is PostCreationException) {
      print('📝 [NewPostScreen] PostCreationException detected');
      getErrorSnackBar(context, 'post_creation_failed');
    } else {
      print('❓ [NewPostScreen] Unknown error type, using generic error');
      getErrorSnackBar(context, 'generic_error');
    }
  }

  /// Maps PostValidationException codes to translation keys
  String _getValidationErrorKey(PostValidationException error) {
    switch (error.code) {
      case 'TITLE_EMPTY':
        return 'post_title_empty';
      case 'TITLE_TOO_SHORT':
        return 'post_title_too_short';
      case 'TITLE_TOO_LONG':
        return 'post_title_too_long';
      case 'TITLE_INAPPROPRIATE':
        return 'post_title_inappropriate';
      case 'TITLE_SPAMMY':
        return 'post_title_spammy';
      case 'CONTENT_EMPTY':
        return 'post_content_empty';
      case 'CONTENT_TOO_SHORT':
        return 'post_content_too_short';
      case 'CONTENT_TOO_LONG':
        return 'post_content_too_long';
      case 'CONTENT_TOO_FEW_WORDS':
        return 'post_content_too_few_words';
      case 'CONTENT_TOO_MANY_WORDS':
        return 'post_content_too_many_words';
      case 'CONTENT_INAPPROPRIATE':
        return 'post_content_inappropriate';
      case 'CONTENT_SPAMMY':
        return 'post_content_spammy';
      case 'CATEGORY_INVALID':
        return 'post_category_invalid';
      case 'CATEGORY_INVALID_FORMAT':
        return 'post_category_invalid_format';
      case 'POST_TOO_SHORT_OVERALL':
        return 'post_too_short_overall';
      case 'TITLE_CONTENT_TOO_SIMILAR':
        return 'post_title_content_too_similar';
      default:
        return 'validation_error';
    }
  }

  /// Resets the form to initial state
  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    // Reset to null and let the category loading logic set the default general category
    ref.read(selectedCategoryProvider.notifier).state = null;

    // Reset anonymity state to user's profile setting
    ref.read(currentCommunityProfileProvider).whenData((profile) {
      if (profile != null) {
        ref.read(anonymousPostProvider.notifier).state = profile.isAnonymous;
      } else {
        ref.read(anonymousPostProvider.notifier).state = false;
      }
    });

    ref.read(postContentProvider.notifier).state = '';
    ref.read(postCreationProvider.notifier).reset();
    // Clear attachments
    ref.read(postAttachmentsProvider.notifier).clearAttachments();
  }

  /// Selects a category
  void _selectCategory(PostCategory category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
    Navigator.pop(context);
  }

  /// Toggles anonymity
  void _toggleAnonymity() {
    final current = ref.read(anonymousPostProvider);
    ref.read(anonymousPostProvider.notifier).state = !current;
  }
}

/// Poll Creation Modal Widget
class _PollCreationModal extends ConsumerStatefulWidget {
  final Function(PollAttachmentData) onPollCreated;
  final PollAttachmentData? existingPoll;

  const _PollCreationModal({
    required this.onPollCreated,
    this.existingPoll,
  });

  @override
  ConsumerState<_PollCreationModal> createState() => _PollCreationModalState();
}

class _PollCreationModalState extends ConsumerState<_PollCreationModal> {
  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;
  late bool _isMultiSelect;

  @override
  void initState() {
    super.initState();
    // Initialize with existing poll data if available
    if (widget.existingPoll != null) {
      _questionController =
          TextEditingController(text: widget.existingPoll!.question);
      _optionControllers = widget.existingPoll!.options
          .map((option) => TextEditingController(text: option.text))
          .toList();
      _isMultiSelect = widget.existingPoll!.isMultiSelect;
    } else {
      _questionController = TextEditingController();
      _optionControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      _isMultiSelect = false;
    }

    // Add listeners to trigger validation
    _questionController.addListener(_checkFormValidity);
    for (var controller in _optionControllers) {
      controller.addListener(_checkFormValidity);
    }

    // Check initial validity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFormValidity();
    });
  }

  @override
  void dispose() {
    _questionController.removeListener(_checkFormValidity);
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.removeListener(_checkFormValidity);
      controller.dispose();
    }
    super.dispose();
  }

  bool _isFormValid = false;

  void _checkFormValidity() {
    final isValid = _questionController.text.trim().isNotEmpty &&
        _optionControllers
                .where((controller) => controller.text.trim().isNotEmpty)
                .length >=
            2;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool get _isValid => _isFormValid;

  void _addOption() {
    if (_optionControllers.length < 4) {
      setState(() {
        final newController = TextEditingController();
        newController.addListener(_checkFormValidity);
        _optionControllers.add(newController);
      });
      _checkFormValidity();
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].removeListener(_checkFormValidity);
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
      _checkFormValidity();
    }
  }

  void _createPoll() {
    if (!_isValid) return;

    final options = _optionControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .map((controller) => PollOptionData(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  _optionControllers.indexOf(controller).toString(),
              text: controller.text.trim(),
            ))
        .toList();

    final pollData = PollAttachmentData(
      question: _questionController.text.trim(),
      options: options,
      isMultiSelect: _isMultiSelect,
      closesAt: null,
    );

    widget.onPollCreated(pollData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x),
                ),
                Expanded(
                  child: Text(
                    localizations.translate(widget.existingPoll != null
                        ? 'poll-edit'
                        : 'poll-create'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Create button using shared WidgetsContainer
                shared.WidgetsContainer(
                  backgroundColor:
                      _isValid ? theme.primary[600] : theme.grey[400],
                  borderSide: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: _isValid ? _createPoll : null,
                    child: Text(
                      localizations.translate(
                          widget.existingPoll != null ? 'update' : 'create'),
                      style: TextStyles.footnoteSelected.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question input using CustomTextArea
                  CustomTextArea(
                    controller: _questionController,
                    hint: localizations.translate('poll-question-hint'),
                    prefixIcon: LucideIcons.helpCircle,
                    maxLength: 100,
                    maxLines: 2,
                    height: 80,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Options
                  Text(
                    localizations.translate('poll-options'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Options using CustomTextField
                  ..._optionControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: controller,
                              hint:
                                  '${localizations.translate('poll-option')} ${index + 1}',
                              prefixIcon: LucideIcons.circle,
                              inputType: TextInputType.text,
                              validator: (value) =>
                                  null, // No validation for options
                            ),
                          ),
                          if (_optionControllers.length > 2)
                            IconButton(
                              icon: Icon(LucideIcons.x,
                                  size: 16, color: theme.error[600]),
                              onPressed: () => _removeOption(index),
                            ),
                        ],
                      ),
                    );
                  }),

                  // Add option button using WidgetsContainer
                  if (_optionControllers.length < 4)
                    GestureDetector(
                      onTap: _addOption,
                      child: shared.WidgetsContainer(
                        width: double.infinity,
                        backgroundColor: theme.grey[50],
                        borderSide: BorderSide(
                          color: theme.primary[300]!,
                          style: BorderStyle.solid,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus,
                                size: 16, color: theme.primary[600]),
                            const SizedBox(width: 8),
                            Text(
                              localizations.translate('poll-add-option'),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: theme.primary[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Multi-select switch using PlatformSwitch
                  PlatformSwitch(
                    value: _isMultiSelect,
                    onChanged: (value) =>
                        setState(() => _isMultiSelect = value),
                    label: localizations.translate('poll-multi-select'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Image Preview Modal Widget
class _ImagePreviewModal extends StatefulWidget {
  final dynamic image;
  final List<dynamic> allImages;

  const _ImagePreviewModal({
    required this.image,
    required this.allImages,
  });

  @override
  State<_ImagePreviewModal> createState() => _ImagePreviewModalState();
}

class _ImagePreviewModalState extends State<_ImagePreviewModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allImages.indexOf(widget.image);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header with close button and counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      print('Close button tapped'); // Debug log
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.allImages.length}',
                    style: TextStyles.footnote.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.allImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = widget.allImages[index];
                return Center(
                  child: InteractiveViewer(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: image.localPath != null
                          ? Image.file(
                              File(image.localPath),
                              fit: BoxFit.contain,
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: theme.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.image,
                                size: 64,
                                color: theme.grey[500],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Page indicator dots (only show if more than 1 image)
          if (widget.allImages.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.allImages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
