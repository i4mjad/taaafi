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
import 'package:reboot_app_3/features/groups/providers/filtered_public_groups_provider.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';

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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Attachment previews (if any)
          if (attachmentState.attachmentData != null) ...[
            _buildDetailedAttachmentPreview(theme, localizations, attachmentState),
            horizontalSpace(Spacing.points8),
          ],
          
          const Spacer(),
          
          // Attachment action icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentIcon(
                theme,
                LucideIcons.image,
                () => _handleAttachmentTap(AttachmentType.image),
                isSelected: attachmentState.selectedType == AttachmentType.image,
              ),
              horizontalSpace(Spacing.points12),
              _buildAttachmentIcon(
                theme,
                LucideIcons.barChart3,
                () => _handleAttachmentTap(AttachmentType.poll),
                isSelected: attachmentState.selectedType == AttachmentType.poll,
              ),
              horizontalSpace(Spacing.points12),
              _buildAttachmentIcon(
                theme,
                LucideIcons.users,
                () => _handleAttachmentTap(AttachmentType.groupInvite),
                isSelected: attachmentState.selectedType == AttachmentType.groupInvite,
              ),
              horizontalSpace(Spacing.points16),
              // Post button
              _buildPostButton(theme, localizations),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an attachment icon button
  Widget _buildAttachmentIcon(
    CustomThemeData theme,
    IconData icon,
    VoidCallback onTap,
    {bool isSelected = false}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: theme.primary[300]!) 
              : null,
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
      case AttachmentType.groupInvite:
        return _buildGroupInvitePreview(theme, localizations, attachmentState);
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
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and clear button
          Row(
            children: [
              Icon(LucideIcons.image, size: 16, color: theme.primary[600]),
              const SizedBox(width: 6),
              Text(
                '${imageData.images.length} image${imageData.images.length > 1 ? 's' : ''}',
                style: TextStyles.small.copyWith(
                  color: theme.primary[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearAttachments,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.primary[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: theme.primary[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Image thumbnails
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: imageData.images.take(4).map((image) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.grey[200],
                  image: image.thumbnailPath != null
                      ? DecorationImage(
                          image: FileImage(File(image.thumbnailPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image.thumbnailPath == null
                    ? Icon(
                        LucideIcons.image,
                        size: 16,
                        color: theme.grey[500],
                      )
                    : null,
              );
            }).toList(),
          ),
        ],
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

    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with poll icon and clear button
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16, color: theme.primary[600]),
              const SizedBox(width: 6),
              Text(
                'Poll',
                style: TextStyles.small.copyWith(
                  color: theme.primary[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearAttachments,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.primary[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: theme.primary[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Poll question
          Text(
            pollData.question.isNotEmpty ? pollData.question : 'Poll question',
            style: TextStyles.caption.copyWith(
              color: theme.grey[700],
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Options preview
          ...pollData.options.take(2).map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.primary[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (pollData.options.length > 2)
            Text(
              '+${pollData.options.length - 2} more options',
              style: TextStyles.small.copyWith(
                color: theme.primary[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds group invite attachment preview
  Widget _buildGroupInvitePreview(
    CustomThemeData theme,
    AppLocalizations localizations,
    PostAttachmentsState attachmentState,
  ) {
    final groupData = attachmentState.attachmentData as GroupInviteAttachmentData?;
    if (groupData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.success[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.success[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with group icon and clear button
          Row(
            children: [
              Icon(LucideIcons.users, size: 16, color: theme.success[600]),
              const SizedBox(width: 6),
              Text(
                'Group Invite',
                style: TextStyles.small.copyWith(
                  color: theme.success[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearAttachments,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.success[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: theme.success[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Group info
          Row(
            children: [
              // Group avatar
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.success[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    groupData.groupName.isNotEmpty 
                        ? groupData.groupName[0].toUpperCase() 
                        : 'G',
                    style: TextStyles.small.copyWith(
                      color: theme.success[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupData.groupName,
                      style: TextStyles.small.copyWith(
                        color: theme.success[700],
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${groupData.groupGender} • ${groupData.groupMemberCount}/${groupData.groupCapacity}',
                      style: TextStyles.small.copyWith(
                        color: theme.success[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
        _handleGroupInviteAttachment();
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

  void _handlePollAttachment() {
    _showPollCreationModal();
  }

  void _handleGroupInviteAttachment() {
    _showGroupInviteModal();
  }

  /// Shows poll creation modal
  void _showPollCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _PollCreationModal(
        onPollCreated: (pollData) {
          ref.read(postAttachmentsProvider.notifier).updatePoll(pollData);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Shows group invite modal
  void _showGroupInviteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _GroupInviteModal(
        onGroupSelected: (groupData) {
          ref.read(postAttachmentsProvider.notifier).updateGroupInvite(groupData);
          Navigator.of(context).pop();
        },
      ),
    );
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
        currentAnonymousState: currentAnonymousState,
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
      
      print('📎 [NewPostScreen] Attachment state: ${attachmentState.selectedType}');
      if (attachmentState.attachmentData != null) {
        print('   - Has attachment data: ${attachmentState.attachmentData.runtimeType}');
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
    ref.read(anonymousPostProvider.notifier).state = false;
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
  
  const _PollCreationModal({required this.onPollCreated});

  @override
  ConsumerState<_PollCreationModal> createState() => _PollCreationModalState();
}

class _PollCreationModalState extends ConsumerState<_PollCreationModal> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isMultiSelect = false;
  DateTime? _closesAt;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    if (_questionController.text.trim().isEmpty) return false;
    final validOptions = _optionControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    return validOptions >= 2;
  }

  void _addOption() {
    if (_optionControllers.length < 4) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
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
      closesAt: _closesAt,
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
                    'Create Poll',
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: _isValid ? _createPoll : null,
                  child: Text(
                    'Create',
                    style: TextStyles.footnote.copyWith(
                      color: _isValid ? theme.primary[600] : theme.grey[400],
                      fontWeight: FontWeight.w600,
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
                  // Question input
                  Text(
                    'Poll Question',
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ask your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterStyle: TextStyles.caption.copyWith(
                        color: theme.grey[500],
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  Text(
                    'Options',
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ..._optionControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLength: 100,
                              decoration: InputDecoration(
                                hintText: 'Option ${index + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                counterText: '',
                                suffixIcon: _optionControllers.length > 2
                                    ? IconButton(
                                        icon: Icon(LucideIcons.x, size: 16),
                                        onPressed: () => _removeOption(index),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  if (_optionControllers.length < 4)
                    GestureDetector(
                      onTap: _addOption,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 16, color: theme.primary[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Add Option',
                              style: TextStyles.body.copyWith(
                                color: theme.primary[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // Settings
                  SwitchListTile(
                    title: Text('Allow multiple selections'),
                    value: _isMultiSelect,
                    onChanged: (value) => setState(() => _isMultiSelect = value),
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

/// Group Invite Modal Widget
class _GroupInviteModal extends ConsumerWidget {
  final Function(GroupInviteAttachmentData) onGroupSelected;
  
  const _GroupInviteModal({required this.onGroupSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final groupsAsync = ref.watch(filteredPublicGroupsProvider);

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
                    'Select Group to Invite',
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 48,
                          color: theme.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups available',
                          style: TextStyles.body.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _GroupTile(
                      group: group,
                      onTap: () {
                        final groupData = GroupInviteAttachmentData(
                          groupId: group.id,
                          groupName: group.name,
                          groupGender: group.gender,
                          groupCapacity: group.memberCapacity,
                          groupMemberCount: group.memberCount,
                          joinMethod: group.joinMethod,
                          groupPlusOnly: false, // TODO: Implement Plus-only group logic if needed
                        );
                        onGroupSelected(groupData);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: theme.error[500],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load groups',
                      style: TextStyles.body.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group tile widget
class _GroupTile extends StatelessWidget {
  final GroupEntity group;
  final VoidCallback onTap;
  
  const _GroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.grey[200]!),
        ),
        child: Row(
          children: [
            // Group avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primary[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: TextStyles.h6.copyWith(
                    color: theme.primary[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyles.body.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // TODO: Add Plus-only group indicator if needed
                      // if (group.isPlusOnly)
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 6,
                      //       vertical: 2,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: const Color(0xFFFEBA01),
                      //       borderRadius: BorderRadius.circular(4),
                      //     ),
                      //     child: Text(
                      //       'Plus',
                      //       style: TextStyles.small.copyWith(
                      //         color: Colors.white,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.gender} • ${group.memberCount}/${group.memberCapacity} members',
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
