import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';

import 'package:reboot_app_3/features/community/presentation/widgets/comment_tile_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/reply_input_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/role_chip.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/streak_display_widget.dart';

class CompactCommentModal extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onReplySubmitted;

  const CompactCommentModal({
    super.key,
    required this.comment,
    this.onReplySubmitted,
  });

  @override
  ConsumerState<CompactCommentModal> createState() =>
      _CompactCommentModalState();
}

class _CompactCommentModalState extends ConsumerState<CompactCommentModal> {
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
    final repliesAsync = ref.watch(commentRepliesProvider(widget.comment.id));

    final mediaQuery = MediaQuery.of(context);
    final safeHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final targetHeight = safeHeight * 0.8;

    return SizedBox(
      height: targetHeight,
      child: Container(
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
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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

                    // Header with close button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations.translate('replies'),
                              style: TextStyles.h6.copyWith(
                                color: theme.grey[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                    ),

                    // Original comment (compact view)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WidgetsContainer(
                        child: ResponsedCommentTileWidget(
                          comment: widget.comment,
                          isCondensed: true,
                          onMoreTap: null,
                          onCommentTap: null,
                          onReplyTap: null,
                        ),
                      ),
                    ),

                    // Replies list (non-scrollable inside primary scroll)
                    _buildRepliesList(
                      theme,
                      localizations,
                      repliesAsync,
                    ),
                  ],
                ),
              ),
            ),

            // Simple reply input (no context display)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ReplyInputWidget(
                  postId: widget.comment.postId,
                  parentFor: 'comment',
                  parentId: widget.comment.id,
                  hideReplyContext: true,
                  onReplySubmitted: () {
                    ref.refresh(commentRepliesProvider(widget.comment.id));
                    widget.onReplySubmitted?.call();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesList(
    dynamic theme,
    AppLocalizations localizations,
    AsyncValue<List<Comment>> repliesAsync,
  ) {
    return repliesAsync.when(
      data: (replies) {
        if (replies.isEmpty) {
          return _buildEmptyRepliesState(theme, localizations);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            return CommentTileWidget(
              comment: reply,
              onReplyTap: widget.comment.isTopLevelComment
                  ? () => _openNestedModal(reply) // Only allow one level deeper
                  : null, // Don't allow infinite nesting
              onMoreTap: () => _handleReplyMore(reply),
              onCommentTap: null, // No further compact modal nesting
            );
          },
        );
      },
      loading: () => _buildLoadingState(theme, localizations),
      error: (error, stack) => _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildEmptyRepliesState(
      dynamic theme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 32,
              color: theme.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('no_replies_yet'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(dynamic theme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary[600]),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('loading_replies'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      dynamic theme, AppLocalizations localizations, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 28,
              color: theme.error[500],
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('error_loading_replies'),
              style: TextStyles.body.copyWith(
                color: theme.error[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openNestedModal(Comment reply) {
    // Open another compact modal for the reply
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompactCommentModal(
        comment: reply,
        onReplySubmitted: () {
          // Refresh this level's replies
          ref.refresh(commentRepliesProvider(widget.comment.id));
          widget.onReplySubmitted?.call();
        },
      ),
    );
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

      // Close the modal and refresh
      Navigator.of(context).pop();
      widget.onReplySubmitted?.call();

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

class ResponsedCommentTileWidget extends ConsumerWidget {
  final Comment comment;
  final bool isAuthor;
  final VoidCallback? onMoreTap; // 3 dots - for comment options
  final VoidCallback? onCommentTap; // Comment body tap - for compact modal
  final VoidCallback? onReplyTap;
  final bool isCondensed;

  const ResponsedCommentTileWidget({
    super.key,
    required this.comment,
    this.isAuthor = false,
    this.onMoreTap,
    this.onCommentTap,
    this.onReplyTap,
    this.isCondensed = false,
  });

  /// Helper function to localize special display name constants
  String _getLocalizedDisplayName(
      String displayName, AppLocalizations localizations) {
    switch (displayName) {
      case 'DELETED_USER':
        return localizations.translate('community-deleted-user');
      case 'ANONYMOUS_USER':
        return localizations.translate('community-anonymous');
      default:
        return displayName;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(comment.authorCPId));

    return authorProfileAsync.when(
      data: (authorProfile) {
        final isAuthorAnonymous = authorProfile.isAnonymous;
        final isAuthorPlusUser = authorProfile.hasPlusSubscription();

        return GestureDetector(
          onTap: () =>
              onCommentTap?.call(), // Tap comment to open compact modal
          child: Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar - clickable to show profile
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: CommunityProfileModal(
                        communityProfileId: comment.authorCPId,
                        displayName: authorProfile.displayName,
                        avatarUrl: authorProfile.avatarUrl,
                        isAnonymous: isAuthorAnonymous,
                        isPlusUser: isAuthorPlusUser,
                      ),
                    ),
                  ),
                  child: AvatarWithAnonymity(
                    isDeleted: authorProfile.isDeleted,
                    cpId: comment.authorCPId,
                    isAnonymous: isAuthorAnonymous,
                    size: 32,
                    avatarUrl:
                        isAuthorAnonymous ? null : authorProfile.avatarUrl,
                    isPlusUser: isAuthorPlusUser,
                  ),
                ),

                const SizedBox(width: 16),

                // Comment content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info and timestamp
                      _buildUserInfo(
                          context,
                          ref,
                          theme,
                          localizations,
                          isAuthorAnonymous,
                          authorProfileAsync,
                          isAuthorPlusUser),

                      const SizedBox(height: 8),

                      // Comment body
                      Text(
                        comment.isHidden
                            ? localizations.translate('comment-hidden-by-admin')
                            : comment.body,
                        style: TextStyles.caption.copyWith(
                          color: comment.isHidden
                              ? theme.grey[600]
                              : theme.grey[800],
                          fontSize: 15,
                          height: 1.4,
                          fontStyle: comment.isHidden
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Actions row
                      _buildInteractionButtons(
                          context, ref, theme, localizations),
                    ],
                  ),
                ),
              ],
            ), // Close Row (child of Container)
          ), // Close Container (child of GestureDetector)
        ); // Close GestureDetector
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stackTrace) =>
          _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildLoadingState(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      dynamic theme, AppLocalizations localizations, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: theme.error[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.translate('error_loading_comment'),
              style: TextStyles.body.copyWith(
                color: theme.error[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
      BuildContext context,
      WidgetRef ref,
      dynamic theme,
      AppLocalizations localizations,
      bool isAuthorAnonymous,
      AsyncValue authorProfileAsync,
      bool isAuthorPlusUser) {
    return authorProfileAsync.when(
      data: (authorProfile) {
        final pipelineResult =
            authorProfile?.getDisplayNameWithPipeline() ?? 'Unknown User';
        final displayName =
            _getLocalizedDisplayName(pipelineResult, localizations);

        return Row(
          children: [
            // User info section - similar to post header
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIRST row for badges, timestamp, and 3-dots
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        // Badges container - only add spacing between existing badges
                        Row(
                          children: [
                            // Build badges list dynamically to avoid unnecessary spacing
                            ...() {
                              final List<Widget> badges = [];

                              // Role chip
                              if (authorProfile.role != null &&
                                  authorProfile.role!.isNotEmpty) {
                                badges.add(RoleChip(role: authorProfile.role));
                              }

                              // Streak display
                              if (isAuthorPlusUser &&
                                  authorProfile.shareRelapseStreaks) {
                                badges.add(Consumer(
                                  builder: (context, ref, child) {
                                    final streakAsync = ref.watch(
                                        userStreakCalculatorProvider(
                                            comment.authorCPId));

                                    return streakAsync.when(
                                      data: (streakDays) {
                                        if (streakDays == null ||
                                            streakDays <= 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return StreakDisplayWidget(
                                          streakDays: streakDays,
                                          fontSize: 8,
                                          iconSize: 8,
                                        );
                                      },
                                      loading: () => const SizedBox.shrink(),
                                      error: (error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    );
                                  },
                                ));
                              }

                              // Author badge
                              if (isAuthor) {
                                badges.add(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.primary[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    localizations.translate('author'),
                                    style: TextStyles.tiny.copyWith(
                                      color: theme.primary[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ));
                              }

                              // Add spacing only between existing badges
                              final List<Widget> spacedBadges = [];
                              for (int i = 0; i < badges.length; i++) {
                                spacedBadges.add(badges[i]);
                                // Add spacing between badges (not after the last one)
                                if (i < badges.length - 1) {
                                  spacedBadges.add(const SizedBox(width: 6));
                                }
                              }

                              return spacedBadges;
                            }(),
                          ],
                        ),

                        // Spacer between badges and timestamp/3dots
                        const Spacer(),

                        // Timestamp
                        Text(
                          _formatTimestamp(comment.createdAt),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 3 dots button
                        if (onMoreTap != null)
                          GestureDetector(
                            onTap: onMoreTap,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                LucideIcons.moreHorizontal,
                                size: 16,
                                color: theme.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // SECOND row for name only
                  Row(
                    children: [
                      // Display name - clickable
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: CommunityProfileModal(
                              communityProfileId: comment.authorCPId,
                              displayName: authorProfile.displayName,
                              avatarUrl: authorProfile.avatarUrl,
                              isAnonymous: isAuthorAnonymous,
                              isPlusUser: isAuthorPlusUser,
                            ),
                          ),
                        ),
                        child: Text(
                          displayName,
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.primary[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: Text(
              'Loading...',
              style: TextStyles.footnoteSelected.copyWith(
                color: theme.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      error: (error, stackTrace) => Row(
        children: [
          Expanded(
            child: Text(
              'Unknown User',
              style: TextStyles.footnoteSelected.copyWith(
                color: theme.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations localizations,
  ) {
    return Row(
      children: [
        // Like button with user state
        _CommentInteractionButton(
          comment: comment,
          interactionValue: 1,
          icon: LucideIcons.thumbsUp,
          count: comment.likeCount,
        ),

        const SizedBox(width: 24),

        // Dislike button with user state
        _CommentInteractionButton(
          comment: comment,
          interactionValue: -1,
          icon: LucideIcons.thumbsDown,
          count: comment.dislikeCount,
        ),

        const SizedBox(width: 24),

        // Reply button
        if (!isCondensed) _buildReplyButton(context, ref, theme, localizations),

        const Spacer(),
      ],
    );
  }

  Widget _buildReplyButton(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations localizations,
  ) {
    return GestureDetector(
      onTap: onReplyTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 18,
              color: theme.grey[500],
            ),
            if (comment.hasReplies) ...[
              const SizedBox(width: 6),
              Text(
                comment.replyCount.toString(),
                style: TextStyles.tiny.copyWith(
                  color: theme.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Separate widget to handle comment interaction state
class _CommentInteractionButton extends ConsumerWidget {
  final Comment comment;
  final int interactionValue;
  final IconData icon;
  final int count;

  const _CommentInteractionButton({
    required this.comment,
    required this.interactionValue,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    // Watch user's interaction with this comment
    final userInteractionAsync = ref.watch(
      userInteractionProvider((
        targetType: 'comment',
        targetId: comment.id,
        userCPId: '',
      )),
    );

    final isActive = userInteractionAsync.maybeWhen(
      data: (interaction) => interaction?.value == interactionValue,
      orElse: () => false,
    );

    final isLoading = userInteractionAsync.isLoading;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isLoading ? () {} : () => _handleInteraction(ref),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: isActive ? theme.primary[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isLoading
                  ? theme.grey[400]
                  : isActive
                      ? theme.primary[600]
                      : theme.grey[500],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: TextStyles.tiny.copyWith(
            color: theme.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _handleInteraction(WidgetRef ref) {
    try {
      // Get current user's interaction state
      final userInteractionAsync = ref.read(
        userInteractionProvider((
          targetType: 'comment',
          targetId: comment.id,
          userCPId: '',
        )),
      );

      userInteractionAsync.whenData((currentInteraction) {
        // If user already has this interaction, toggle it off (neutral)
        final newValue = currentInteraction?.value == interactionValue
            ? 0
            : interactionValue;

        // Trigger the interaction
        ref
            .read(commentInteractionProvider(comment.id).notifier)
            .interact(newValue);
      });
    } catch (e) {
      // Handle errors silently to prevent UI crashes
      debugPrint('Error handling comment interaction: $e');
    }
  }
}
