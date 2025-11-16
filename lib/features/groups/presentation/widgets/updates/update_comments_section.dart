import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

/// Widget to display comments on an update
class UpdateCommentsSection extends ConsumerStatefulWidget {
  final String updateId;
  final String groupId;
  final int maxVisible;

  const UpdateCommentsSection({
    super.key,
    required this.updateId,
    required this.groupId,
    this.maxVisible = 3,
  });

  @override
  ConsumerState<UpdateCommentsSection> createState() =>
      _UpdateCommentsSectionState();
}

class _UpdateCommentsSectionState extends ConsumerState<UpdateCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref.watch(updateCommentsProvider(widget.updateId));

    return commentsAsync.when(
      data: (comments) {
        final visibleComments = widget.maxVisible > 0
            ? comments.take(widget.maxVisible).toList()
            : comments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comments.isNotEmpty) ...[
              // Comments list
              ...visibleComments.map((comment) {
                return _buildCommentTile(context, ref, theme, l10n, comment);
              }),

              // View all button if there are more
              if (comments.length > widget.maxVisible) ...[
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full comments screen
                  },
                  child: Text(
                    l10n
                        .translate('view-all-comments')
                        .replaceAll('{count}', comments.length.toString()),
                    style: TextStyles.small.copyWith(
                      color: theme.primary[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],

            // Add comment input
            _buildCommentInput(context, theme, l10n),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading comments',
          style: TextStyles.small.copyWith(color: theme.error[600]),
        ),
      ),
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
    dynamic comment,
  ) {
    final authorAsync =
        ref.watch(communityProfileByIdProvider(comment.authorCpId));
    final currentProfile = ref.watch(currentCommunityProfileProvider).value;
    final isOwnComment = currentProfile?.id == comment.authorCpId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: authorAsync.when(
                data: (author) {
                  if (comment.isAnonymous) {
                    return Icon(LucideIcons.user,
                        size: 16, color: theme.grey[600]);
                  }
                  return Text(
                    author.displayName.substring(0, 1).toUpperCase(),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                loading: () =>
                    Icon(LucideIcons.user, size: 16, color: theme.grey[600]),
                error: (_, __) =>
                    Icon(LucideIcons.user, size: 16, color: theme.grey[600]),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name
                      authorAsync.when(
                        data: (author) => Text(
                          comment.isAnonymous
                              ? l10n.translate('anonymous-member')
                              : author.displayName ?? 'Unknown',
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[900],
                            fontSize: 12,
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[900],
                            fontSize: 12,
                          ),
                        ),
                        error: (_, __) => Text(
                          'Member',
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Comment text
                      Text(
                        comment.content,
                        style: TextStyles.small.copyWith(
                          color: theme.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Timestamp and actions
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt, l10n),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    if (isOwnComment) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteComment(ref, comment.id),
                        child: Text(
                          l10n.translate('delete-comment-update'),
                          style: TextStyles.caption.copyWith(
                            color: theme.error[600],
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l10n.translate('add-comment'),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyles.small,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.send, size: 20),
                onPressed: _postComment,
                color: theme.primary[600],
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) =>
                    setState(() => _isAnonymous = value ?? false),
              ),
              Text(
                l10n.translate('post-anonymously'),
                style: TextStyles.caption.copyWith(color: theme.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return l10n.translate('just-now-time');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${l10n.translate('minutes-short-time')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${l10n.translate('hours-short-time')}';
    } else {
      return '${difference.inDays}${l10n.translate('days-short-time')}';
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final controller = ref.read(postCommentControllerProvider.notifier);
      await controller.postComment(
        updateId: widget.updateId,
        content: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      _commentController.clear();
      setState(() => _isAnonymous = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteComment(WidgetRef ref, String commentId) async {
    try {
      final controller = ref.read(deleteCommentControllerProvider.notifier);
      await controller.deleteComment(commentId: commentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
