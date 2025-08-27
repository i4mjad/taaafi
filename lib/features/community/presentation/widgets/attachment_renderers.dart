import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';

/// Main attachment renderer that dispatches to specific renderers
class AttachmentRenderer extends ConsumerWidget {
  final Post post;
  final bool isListView;

  const AttachmentRenderer({
    super.key,
    required this.post,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!post.attachmentTypes.contains('image') && 
        !post.attachmentTypes.contains('poll') && 
        !post.attachmentTypes.contains('group_invite')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        
        // Render based on attachment type
        if (post.attachmentTypes.contains('image'))
          _ImageAttachmentRenderer(
            post: post,
            isListView: isListView,
          ),
        
        if (post.attachmentTypes.contains('poll'))
          _PollAttachmentRenderer(
            post: post,
            isListView: isListView,
          ),
        
        if (post.attachmentTypes.contains('group_invite'))
          _GroupInviteAttachmentRenderer(
            post: post,
            isListView: isListView,
          ),
      ],
    );
  }
}

/// Image attachment renderer with Threads-style grid layout
class _ImageAttachmentRenderer extends StatelessWidget {
  final Post post;
  final bool isListView;

  const _ImageAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final imageAttachments = post.attachmentsSummary
        .where((attachment) => attachment['type'] == 'image')
        .toList();

    if (imageAttachments.isEmpty) return const SizedBox.shrink();

    return _buildImageGrid(context, theme, imageAttachments);
  }

  Widget _buildImageGrid(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    if (isListView) {
      return _buildListViewImages(context, theme, images);
    } else {
      return _buildDetailViewImages(context, theme, images);
    }
  }

  Widget _buildListViewImages(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    const double imageSize = 72.0;
    const double spacing = 8.0;
    const double borderRadius = 8.0;

    return SizedBox(
      height: images.length > 2 ? imageSize * 2 + spacing : imageSize,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: images.length > 4 ? 4 : images.length,
        itemBuilder: (context, index) {
          final isLastItem = index == 3 && images.length > 4;
          final remainingCount = images.length - 4;

          return GestureDetector(
            onTap: () => _openImageViewer(context, images, index),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: theme.grey[100],
                    image: images[index]['thumbnailUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(images[index]['thumbnailUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: images[index]['thumbnailUrl'] == null
                      ? Center(
                          child: Icon(
                            LucideIcons.image,
                            color: theme.grey[400],
                            size: 24,
                          ),
                        )
                      : null,
                ),
                if (isLastItem && remainingCount > 0)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: TextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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

  Widget _buildDetailViewImages(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: _buildResponsiveImageGrid(context, theme, images),
    );
  }

  Widget _buildResponsiveImageGrid(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    const double borderRadius = 12.0;
    const double spacing = 4.0;

    if (images.length == 1) {
      return _buildSingleImage(context, images.first, borderRadius);
    } else if (images.length == 2) {
      return _buildTwoImages(context, images, borderRadius, spacing);
    } else if (images.length == 3) {
      return _buildThreeImages(context, images, borderRadius, spacing);
    } else {
      return _buildFourImages(context, images, borderRadius, spacing);
    }
  }

  Widget _buildSingleImage(
    BuildContext context,
    Map<String, dynamic> image,
    double borderRadius,
  ) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, [image], 0),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: AppTheme.of(context).grey[100],
            image: image['thumbnailUrl'] != null
                ? DecorationImage(
                    image: NetworkImage(image['thumbnailUrl']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: image['thumbnailUrl'] == null
              ? Center(
                  child: Icon(
                    LucideIcons.image,
                    color: AppTheme.of(context).grey[400],
                    size: 32,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTwoImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(child: _buildImageTile(context, images[0], borderRadius, 0)),
        SizedBox(width: spacing),
        Expanded(child: _buildImageTile(context, images[1], borderRadius, 1)),
      ],
    );
  }

  Widget _buildThreeImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildImageTile(context, images[0], borderRadius, 0),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildImageTile(context, images[1], borderRadius, 1)),
              SizedBox(height: spacing),
              Expanded(child: _buildImageTile(context, images[2], borderRadius, 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImageTile(context, images[0], borderRadius, 0)),
              SizedBox(width: spacing),
              Expanded(child: _buildImageTile(context, images[1], borderRadius, 1)),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImageTile(context, images[2], borderRadius, 2)),
              SizedBox(width: spacing),
              Expanded(child: _buildImageTile(context, images[3], borderRadius, 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    Map<String, dynamic> image,
    double borderRadius,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, [image], index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppTheme.of(context).grey[100],
          image: image['thumbnailUrl'] != null
              ? DecorationImage(
                  image: NetworkImage(image['thumbnailUrl']),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image['thumbnailUrl'] == null
            ? Center(
                child: Icon(
                  LucideIcons.image,
                  color: AppTheme.of(context).grey[400],
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<Map<String, dynamic>> images,
    int initialIndex,
  ) {
    // TODO: Implement image viewer modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Viewer'),
        content: const Text('Image viewer not implemented yet'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Poll attachment renderer with Threads-style design
class _PollAttachmentRenderer extends ConsumerWidget {
  final Post post;
  final bool isListView;

  const _PollAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final pollSummary = post.attachmentsSummary
        .firstWhere((a) => a['type'] == 'poll', orElse: () => <String, dynamic>{});

    if (pollSummary.isEmpty) return const SizedBox.shrink();

    if (isListView) {
      return _buildListViewPoll(context, theme, localizations, pollSummary);
    } else {
      return _buildDetailViewPoll(context, theme, localizations, pollSummary, ref);
    }
  }

  Widget _buildListViewPoll(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> pollSummary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary[100]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.barChart3,
            size: 16,
            color: theme.primary[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pollSummary['title'] ?? localizations.translate('poll'),
              style: TextStyles.footnote.copyWith(
                color: theme.primary[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.primary[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              localizations.translate('poll'),
              style: TextStyles.tiny.copyWith(
                color: theme.primary[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailViewPoll(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> pollSummary,
    WidgetRef ref,
  ) {
    // TODO: Load full poll data from attachments subcollection
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 20,
                color: theme.primary[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pollSummary['title'] ?? localizations.translate('poll'),
                  style: TextStyles.bodyLarge.copyWith(
                    color: theme.primary[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Poll content will be loaded from subcollection',
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Group invite attachment renderer
class _GroupInviteAttachmentRenderer extends StatelessWidget {
  final Post post;
  final bool isListView;

  const _GroupInviteAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final inviteSummary = post.attachmentsSummary
        .firstWhere((a) => a['type'] == 'group_invite', orElse: () => <String, dynamic>{});

    if (inviteSummary.isEmpty) return const SizedBox.shrink();

    if (isListView) {
      return _buildListViewInvite(context, theme, localizations, inviteSummary);
    } else {
      return _buildDetailViewInvite(context, theme, localizations, inviteSummary);
    }
  }

  Widget _buildListViewInvite(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> inviteSummary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.success[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success[100]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.users,
            size: 16,
            color: theme.success[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inviteSummary['groupName'] ?? localizations.translate('group-invite'),
              style: TextStyles.footnote.copyWith(
                color: theme.success[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.success[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              localizations.translate('invite'),
              style: TextStyles.tiny.copyWith(
                color: theme.success[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailViewInvite(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> inviteSummary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.success[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.success[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 20,
                  color: theme.success[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inviteSummary['groupName'] ?? localizations.translate('group-invite'),
                      style: TextStyles.bodyLarge.copyWith(
                        color: theme.success[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Group details will be loaded from subcollection',
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement join group functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localizations.translate('join-group'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
