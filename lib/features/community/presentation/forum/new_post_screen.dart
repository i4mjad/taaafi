import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final int _maxTitleCharacters = 300;
  final int _maxContentCharacters = 5000;

  // Future attachment preparation - commented out for now
  // final List<PostAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    // Auto-focus the title field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  bool get _canPost {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final selectedCategory = ref.read(selectedCategoryProvider);
    return title.isNotEmpty && content.isNotEmpty && selectedCategory != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(postCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isAnonymous = ref.watch(anonymousPostProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.translate('new_thread'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _canPost ? _handlePost : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    _canPost ? theme.primary[500] : theme.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                localizations.translate('post'),
                style: TextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Community Selection Row (like Reddit)
          Container(
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
                // Anonymous Toggle
                GestureDetector(
                  onTap: () {
                    ref.read(anonymousPostProvider.notifier).state =
                        !isAnonymous;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAnonymous ? theme.primary[100] : theme.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAnonymous
                            ? theme.primary[300]!
                            : theme.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off_outlined,
                          size: 14,
                          color: isAnonymous
                              ? theme.primary[600]
                              : theme.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          localizations.translate('post_anonymously'),
                          style: TextStyles.caption.copyWith(
                            color: isAnonymous
                                ? theme.primary[600]
                                : theme.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: theme.grey[200], height: 1),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  Container(
                    width: double.infinity,
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      maxLines: null,
                      maxLength: _maxTitleCharacters,
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
                        counterText: '',
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Selection (like Reddit's flair)
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showCategorySelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.grey[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 16,
                                  color: theme.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  selectedCategory?.getDisplayName(
                                          localizations.locale.languageCode) ??
                                      localizations
                                          .translate('select_category'),
                                  style: TextStyles.caption.copyWith(
                                    color: selectedCategory != null
                                        ? theme.grey[700]
                                        : theme.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: theme.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content Input
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: null,
                    minLines: 8,
                    maxLength: _maxContentCharacters,
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
                      counterText: '',
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // Attachments Preview (for future implementation) - commented out for now
                  // if (_attachments.isNotEmpty) ...[
                  //   _buildAttachmentsPreview(),
                  //   const SizedBox(height: 16),
                  // ],
                ],
              ),
            ),
          ),

          // Bottom Section with media options and character count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                top: BorderSide(color: theme.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                // Media Options - commented out for now
                // Row(
                //   children: [
                //     _buildMediaOption(
                //       icon: Icons.image_outlined,
                //       label: localizations.translate('photo'),
                //       onTap: () => _handleAddAttachment(AttachmentType.image),
                //     ),
                //     const SizedBox(width: 20),
                //     _buildMediaOption(
                //       icon: Icons.videocam_outlined,
                //       label: localizations.translate('video'),
                //       onTap: () => _handleAddAttachment(AttachmentType.video),
                //     ),
                //     const SizedBox(width: 20),
                //     _buildMediaOption(
                //       icon: Icons.poll_outlined,
                //       label: localizations.translate('poll'),
                //       onTap: () => _handleAddAttachment(AttachmentType.poll),
                //     ),
                //     const SizedBox(width: 20),
                //     _buildMediaOption(
                //       icon: Icons.link_outlined,
                //       label: localizations.translate('link'),
                //       onTap: () => _handleAddAttachment(AttachmentType.link),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),
                // Character counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${localizations.translate('title')}: ${_titleController.text.length}/$_maxTitleCharacters',
                      style: TextStyles.caption.copyWith(
                        color: _titleController.text.length >
                                _maxTitleCharacters * 0.8
                            ? theme.error[500]
                            : theme.grey[500],
                      ),
                    ),
                    Text(
                      '${localizations.translate('content')}: ${_contentController.text.length}/$_maxContentCharacters',
                      style: TextStyles.caption.copyWith(
                        color: _contentController.text.length >
                                _maxContentCharacters * 0.8
                            ? theme.error[500]
                            : theme.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelector(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(postCategoriesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('select_category'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final displayName = category
                        .getDisplayName(localizations.locale.languageCode);

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state =
                            category;
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: category.color),
                        ),
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
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Text(
                  'Error loading categories',
                  style: TextStyles.caption.copyWith(color: theme.error[500]),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Attachment preview methods - commented out for now
  // Widget _buildAttachmentsPreview() {
  //   final theme = AppTheme.of(context);
  //
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: theme.grey[50],
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: theme.grey[200]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Attachments',
  //           style: TextStyles.caption.copyWith(
  //             color: theme.grey[700],
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         // This will show attachment previews when implemented
  //         ..._attachments
  //             .map((attachment) => _buildAttachmentPreview(attachment)),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildAttachmentPreview(PostAttachment attachment) {
  //   final theme = AppTheme.of(context);
  //
  //   return Container(
  //     padding: const EdgeInsets.all(8),
  //     margin: const EdgeInsets.only(bottom: 8),
  //     decoration: BoxDecoration(
  //       color: theme.backgroundColor,
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: theme.grey[200]!),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           attachment.icon,
  //           color: attachment.color,
  //           size: 20,
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: Text(
  //             attachment.title ?? attachment.displayName,
  //             style: TextStyles.caption.copyWith(
  //               color: theme.grey[700],
  //             ),
  //           ),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.close, size: 16),
  //           onPressed: () {
  //             setState(() {
  //               _attachments.remove(attachment);
  //             });
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Media option widget - commented out for now
  // Widget _buildMediaOption({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   final theme = AppTheme.of(context);
  //
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: theme.grey[100],
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             icon,
  //             color: theme.grey[600],
  //             size: 20,
  //           ),
  //           const SizedBox(width: 4),
  //           Text(
  //             label,
  //             style: TextStyles.caption.copyWith(
  //               color: theme.grey[600],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _handlePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final selectedCategory = ref.read(selectedCategoryProvider);
    final isAnonymous = ref.read(anonymousPostProvider);

    if (title.isEmpty || content.isEmpty || selectedCategory == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create post using repository
      final repository = ref.read(forumRepositoryProvider);
      final postId = await repository.createPost(
        title: title,
        content: content,
        categoryId: selectedCategory.id,
        isAnonymous: isAnonymous,
        attachmentUrls: [], // _attachments.map((a) => a.url).toList(), - commented out for now
      );

      // Hide loading indicator
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('post_created')),
          backgroundColor: AppTheme.of(context).primary[500],
        ),
      );

      // Reset state and navigate back
      _resetForm();
      context.pop();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: AppTheme.of(context).error[500],
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(anonymousPostProvider.notifier).state = false;
    ref.read(postContentProvider.notifier).state = '';
    // _attachments.clear(); - commented out for now
  }

  // Attachment handling methods - commented out for now
  // void _handleAddAttachment(AttachmentType type) {
  //   // TODO: Implement attachment handling based on type
  //   switch (type) {
  //     case AttachmentType.image:
  //       _handleAddPhoto();
  //       break;
  //     case AttachmentType.video:
  //       _handleAddVideo();
  //       break;
  //     case AttachmentType.poll:
  //       _handleAddPoll();
  //       break;
  //     case AttachmentType.link:
  //       _handleAddLink();
  //       break;
  //     default:
  //       break;
  //   }
  // }

  // void _handleAddPhoto() {
  //   // TODO: Implement photo selection
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text(AppLocalizations.of(context).translate('photo_coming_soon')),
  //     ),
  //   );
  // }

  // void _handleAddVideo() {
  //   // TODO: Implement video selection
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text(AppLocalizations.of(context).translate('video_coming_soon')),
  //     ),
  //   );
  // }

  // void _handleAddPoll() {
  //   // TODO: Implement poll creation
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text(AppLocalizations.of(context).translate('poll_coming_soon')),
  //     ),
  //   );
  // }

  // void _handleAddLink() {
  //   // TODO: Implement link attachment
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text(AppLocalizations.of(context).translate('link_coming_soon')),
  //     ),
  //   );
  // }
}
