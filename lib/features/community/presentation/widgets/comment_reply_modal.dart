import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';

import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

import 'package:reboot_app_3/features/community/presentation/widgets/comment_tile_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/reply_input_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';

class CommentReplyModal extends ConsumerStatefulWidget {
  final Comment parentComment;
  final int nestingLevel;
  final VoidCallback? onReplySubmitted;

  const CommentReplyModal({
    super.key,
    required this.parentComment,
    this.nestingLevel = 0,
    this.onReplySubmitted,
  });

  @override
  ConsumerState<CommentReplyModal> createState() => _CommentReplyModalState();
}

class _CommentReplyModalState extends ConsumerState<CommentReplyModal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final repliesAsync =
        ref.watch(commentRepliesProvider(widget.parentComment.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.grey[300]!.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              _buildHeader(theme, localizations),

              // Content area
              Expanded(
                child: Column(
                  children: [
                    // Parent comment (condensed view)
                    _buildParentCommentView(theme, localizations),

                    // Divider
                    Divider(
                      color: theme.grey[200],
                      height: 1,
                    ),

                    // Replies list
                    Expanded(
                      child: _buildRepliesList(
                          theme, localizations, repliesAsync, scrollController),
                    ),
                  ],
                ),
              ),

              // Reply input
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: theme.grey[200]!),
                    ),
                  ),
                  child: ReplyInputWidget(
                    postId: widget.parentComment.postId,
                    parentFor: 'comment',
                    parentId: widget.parentComment.id,
                    replyToComment: widget.parentComment,
                    onReplySubmitted: () {
                      // Refresh replies and notify parent
                      ref.refresh(
                          commentRepliesProvider(widget.parentComment.id));
                      widget.onReplySubmitted?.call();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button (if nested)
          if (widget.nestingLevel > 0) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  localizations.locale.languageCode == 'ar'
                      ? LucideIcons.chevronRight
                      : LucideIcons.chevronLeft,
                  size: 20,
                  color: theme.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('reply_modal_title'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.nestingLevel > 0)
                  Text(
                    localizations.translate('thread_depth').replaceAll(
                          '{level}',
                          widget.nestingLevel.toString(),
                        ),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[500],
                    ),
                  ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.x,
                size: 20,
                color: theme.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCommentView(
      dynamic theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            localizations.translate('parent_comment'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          verticalSpace(Spacing.points8),

          // Comment tile (condensed)
          CommentTileWidget(
            comment: widget.parentComment,
            isCondensed: true,
            onMoreTap: null, // Disable options for condensed parent view
            onCommentTap: null, // Disable tap for condensed parent view
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesList(
    dynamic theme,
    AppLocalizations localizations,
    AsyncValue<List<Comment>> repliesAsync,
    ScrollController scrollController,
  ) {
    return repliesAsync.when(
      data: (replies) {
        if (replies.isEmpty) {
          return _buildEmptyRepliesState(theme, localizations);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: CommentTileWidget(
                comment: reply,
                nestingLevel: widget.nestingLevel + 1,
                onReplyTap: () => _openNestedReplyModal(reply),
                onMoreTap: () => _handleReplyMore(reply), // 3 dots for options
                onCommentTap: null, // No compact modal in reply modal
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildEmptyRepliesState(
      dynamic theme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 32,
              color: theme.grey[400],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                localizations.translate('no_replies_yet'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                localizations.translate('be_first_to_reply'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(dynamic theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: const Spinner(),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                'Loading replies...',
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      dynamic theme, AppLocalizations localizations, Object error) {
    print(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 32,
              color: theme.error[500],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                localizations.translate('error_loading_replies'),
                style: TextStyles.body.copyWith(
                  color: theme.error[600],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                error.toString(),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNestedReplyModal(Comment reply) {
    // Push modal to stack and open new modal
    ref.read(nestedModalStackProvider.notifier).pushModal(reply.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentReplyModal(
        parentComment: reply,
        nestingLevel: widget.nestingLevel + 1,
        onReplySubmitted: () {
          // Refresh this level's replies
          ref.refresh(commentRepliesProvider(widget.parentComment.id));
          widget.onReplySubmitted?.call();
        },
      ),
    ).then((_) {
      // Pop modal from stack when closed
      ref.read(nestedModalStackProvider.notifier).popModal();
    });
  }

  void _handleReplyMore(Comment reply) {
    _showCommentOptionsModal(context, reply);
  }

  void _showCommentOptionsModal(BuildContext context, Comment comment) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.read(currentCommunityProfileProvider);

    // Check if current user owns this comment
    bool isOwnComment = false;
    currentProfileAsync.whenData((profile) {
      isOwnComment = profile?.id == comment.authorCPId;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Report Comment Option
            _buildCommentOption(
              context,
              theme,
              localizations,
              icon: LucideIcons.flag,
              title: localizations.translate('report_comment'),
              subtitle: localizations.translate('report_inappropriate_content'),
              onTap: () {
                Navigator.of(context).pop();
                _showReportCommentModal(context, comment);
              },
            ),

            // Delete Comment Option (only if user owns the comment)
            if (isOwnComment) ...[
              const SizedBox(height: 8),
              _buildCommentOption(
                context,
                theme,
                localizations,
                icon: LucideIcons.trash2,
                title: localizations.translate('delete_comment'),
                subtitle: localizations.translate('permanently_delete_comment'),
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteCommentConfirmation(context, comment);
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentOption(
    BuildContext context,
    dynamic theme,
    AppLocalizations localizations, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive ? theme.error[50] : theme.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? theme.error[100] : theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? theme.error[600] : theme.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? theme.error[700] : theme.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: isDestructive ? theme.error[600] : theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              localizations.locale.languageCode == 'ar'
                  ? LucideIcons.chevronLeft
                  : LucideIcons.chevronRight,
              size: 16,
              color: isDestructive ? theme.error[500] : theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportCommentModal(BuildContext context, Comment comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportContentModal(
          contentType: ReportContentType.comment,
          comment: comment,
        ),
      ),
    );
  }

  void _showDeleteCommentConfirmation(BuildContext context, Comment comment) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Header with icon and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.error[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 24,
                      color: theme.error[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('delete_comment'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('confirm_delete_comment'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizations.translate('cancel'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Delete button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _deleteComment(context, comment);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.error[500],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizations.translate('delete'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Add safe area padding for devices with bottom notches
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _deleteComment(BuildContext context, Comment comment) async {
    try {
      await ref.read(forumRepositoryProvider).deleteComment(comment.id);

      // Refresh the replies list
      ref.refresh(commentRepliesProvider(widget.parentComment.id));

      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: AppTheme.of(context).success[600],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment'),
            backgroundColor: AppTheme.of(context).error[600],
          ),
        );
      }
    }
  }
}
