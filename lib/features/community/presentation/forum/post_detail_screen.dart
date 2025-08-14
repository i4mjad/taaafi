import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_header_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_content_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_interactions_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_list_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/reply_input_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/compact_comment_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_reply_modal.dart';

import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  Comment? _replyToComment; // Store comment for reply context

  @override
  void initState() {
    super.initState();
    // Initialize anonymity state based on user's profile setting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentCommunityProfileProvider).whenData((profile) {
        if (profile != null) {
          ref.read(anonymousPostProvider.notifier).state = profile.isAnonymous;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final replyState = ref.watch(replyStateProvider);

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return _buildPostNotFound(theme, localizations);
        }

        return Scaffold(
            appBar: plainAppBar(
                context, ref, localizations.translate('thread'), false, true,
                actions: [
                  // More actions button
                  GestureDetector(
                    onTap: () => showPostOptions(context, post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        LucideIcons.moreHorizontal,
                        color: theme.grey[600],
                      ),
                    ),
                  ),
                ]),
            backgroundColor: theme.backgroundColor,
            body: Stack(
              children: [
                // Main content - constrained properly
                Positioned.fill(
                  bottom: 100, // Leave space for reply input
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main post section
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Post header
                              PostHeaderWidget(
                                post: post,
                                onMorePressed: () =>
                                    showPostOptions(context, post),
                              ),

                              const SizedBox(height: 16),

                              // Post content
                              PostContentWidget(post: post),
                            ],
                          ),
                        ),

                        // Post interactions
                        PostInteractionsWidget(
                          post: post,
                          commentCount: _getCommentCount(commentsAsync),
                          onCommentTap: () => _scrollToComments(),
                        ),

                        // Divider
                        Divider(
                          color: theme.grey[200],
                          height: 1,
                        ),

                        // Comments section
                        CommentListWidget(
                          postId: widget.postId,
                          postAuthorCPId: post.authorCPId,
                          onCommentMore:
                              _handleCommentTap, // Comment tap opens compact modal
                          onCommentReply:
                              _handleCommentReply, // Reply button shows input
                          onCommentOptions:
                              _showCommentOptionsModal, // 3 dots opens options
                        ),

                        // Add bottom padding to account for floating reply input
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Floating reply section (only show if commenting is allowed)
                if (post.isCommentingAllowed)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: theme.grey[300]!.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: ReplyInputWidget(
                          postId: widget.postId,
                          parentFor: replyState.isReplying ? 'comment' : 'post',
                          parentId: replyState.isReplying
                              ? replyState.replyToCommentId
                              : widget.postId,
                          replyingToUsername: replyState.replyToUsername,
                          replyToComment:
                              replyState.isReplying ? _replyToComment : null,
                          hideReplyContext: !replyState.isReplying,
                          onReplySubmitted: () async {
                            // Store comment reference before clearing
                            final commentToShow = _replyToComment;
                            
                            // Handle reply submission
                            _handleReplySubmitted();
                            
                            // Clear reply state first
                            ref.read(replyStateProvider.notifier).cancelReply();
                            _replyToComment = null;
                            
                            // Wait for the comments to refresh and then show modal
                            if (commentToShow != null) {
                              _showCommentReplyModalAfterSubmit(commentToShow);
                            }
                          },
                          onCancelReply: () {
                            // Clear reply state and comment when user cancels
                            ref.read(replyStateProvider.notifier).cancelReply();
                            _replyToComment = null;
                          },
                        ),
                      ),
                    ),
                  ),

                // Show message when commenting is disabled
                if (!post.isCommentingAllowed)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.ban,
                            size: 20,
                            color: theme.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations
                                  .translate('commenting_disabled_on_post'),
                              style: TextStyles.body.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ));
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildPostNotFound(dynamic theme, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('post_not_found'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('post_not_found_description'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(dynamic theme) {
    return Center(
      child: Spinner(
        valueColor: theme.primary[600],
      ),
    );
  }

  Widget _buildErrorState(
    dynamic theme,
    AppLocalizations localizations,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.error[500],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('error_loading_post'),
            style: TextStyles.footnote.copyWith(
              color: theme.error[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getCommentCount(AsyncValue<List<Comment>> commentsAsync) {
    return commentsAsync.maybeWhen(
      data: (comments) => comments.length,
      orElse: () => 0,
    );
  }

  void _scrollToComments() {
    // Scroll to the comments section
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent * 0.6,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleCommentTap(Comment comment) {
    // Comment body tap -> show compact modal with comment and its replies
    _showCompactCommentModal(context, comment);
  }

  void _handleCommentReply(Comment comment) {
    // Reply button tap -> show reply input in post screen
    _showReplyInputInPost(comment);
  }

  void _handleReplySubmitted() {
    // Refresh comments when a new reply is submitted
    ref.refresh(postCommentsProvider(widget.postId));
  }

  void showPostOptions(BuildContext context, dynamic post) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.read(currentCommunityProfileProvider);

    // Check if current user owns this post
    bool isOwnPost = false;
    currentProfileAsync.whenData((profile) {
      isOwnPost = profile?.id == post.authorCPId;
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

            // Report Post Option
            _buildModalOption(
              context,
              theme,
              localizations,
              icon: LucideIcons.flag,
              title: localizations.translate('report_post'),
              subtitle: localizations.translate('report_inappropriate_content'),
              onTap: () {
                Navigator.of(context).pop();
                _showReportPostModal(context, post);
              },
            ),

            // Toggle Commenting Option (only if user owns the post)
            if (isOwnPost) ...[
              const SizedBox(height: 8),
              _buildModalOption(
                context,
                theme,
                localizations,
                icon: post.isCommentingAllowed
                    ? LucideIcons.ban
                    : LucideIcons.messageSquare,
                title: post.isCommentingAllowed
                    ? localizations.translate('disable_commenting')
                    : localizations.translate('enable_commenting'),
                subtitle: post.isCommentingAllowed
                    ? localizations.translate('disable_commenting_subtitle')
                    : localizations.translate('enable_commenting_subtitle'),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleCommenting(context, post);
                },
              ),
            ],

            // Delete Post Option (only if user owns the post)
            if (isOwnPost) ...[
              const SizedBox(height: 8),
              _buildModalOption(
                context,
                theme,
                localizations,
                icon: LucideIcons.trash2,
                title: localizations.translate('delete_post'),
                subtitle: localizations.translate('permanently_delete_post'),
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeletePostConfirmation(context, post);
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModalOption(
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

  void _showReportPostModal(BuildContext context, dynamic post) {
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
          contentType: ReportContentType.post,
          post: post,
        ),
      ),
    );
  }

  void _showDeletePostConfirmation(BuildContext context, dynamic post) {
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
                    localizations.translate('delete_post'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('confirm_delete_post'),
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
                        _deletePost(context, post);
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

  void _toggleCommenting(BuildContext context, dynamic post) async {
    // Store a reference to the current context and widget state
    final currentContext = context;
    final wasCommentingAllowed = post.isCommentingAllowed;

    try {
      // Use the repository to toggle commenting
      await ref.read(forumRepositoryProvider).togglePostCommenting(
            postId: post.id,
            isCommentingAllowed: !post.isCommentingAllowed,
          );

      // Show success message only if widget is still mounted and context is still valid
      if (mounted && currentContext.mounted) {
        final messageKey =
            wasCommentingAllowed ? 'commenting_disabled' : 'commenting_enabled';
        getSuccessSnackBar(currentContext, messageKey);
      }
    } catch (e) {
      // Show error message only if widget is still mounted and context is still valid
      if (mounted && currentContext.mounted) {
        getErrorSnackBar(currentContext, 'error_toggle_commenting');
      }
    }
  }

  void _deletePost(BuildContext context, dynamic post) async {
    // Store context reference
    final currentContext = context;

    // Mark as deleted optimistically for immediate UI feedback
    ref.read(optimisticPostStateProvider(post.id).notifier).markAsDeleted();

    // Show brief success message and navigate back immediately
    if (mounted && currentContext.mounted) {
      getSuccessSnackBar(currentContext, 'post_deleted');
      // Use GoRouter navigation instead of Navigator.pop()
      currentContext.pop();
    }

    try {
      // Perform actual deletion in background
      await ref.read(forumRepositoryProvider).deletePost(post.id);

      // Invalidate providers to refresh post feeds
      ref.invalidate(postsProvider);
      ref.invalidate(genderFilteredPostsProvider);
      ref.invalidate(mainScreenPostsProvider);
      ref.invalidate(postsPaginationProvider);
      ref.invalidate(pinnedPostsPaginationProvider);
      ref.invalidate(newsPostsPaginationProvider);
      ref.invalidate(userPostsPaginationProvider);
      ref.invalidate(userLikedPostsPaginationProvider);
      ref.invalidate(userCommentsPaginationProvider);
    } catch (e) {
      // Revert optimistic deletion if failed (though user won't see it since they navigated back)
      ref.read(optimisticPostStateProvider(post.id).notifier).revertDeletion();

      // Show error message if user is still in app and context is valid
      if (mounted && currentContext.mounted) {
        getErrorSnackBar(currentContext, 'error_deleting_post');
      }
    }
  }

  void _showReplyInputInPost(Comment comment) async {
    // Store the comment for preview display
    _replyToComment = comment;

    // Get the actual username from the community profile
    final authorProfile =
        await ref.read(communityProfileByIdProvider(comment.authorCPId).future);
    final displayName = authorProfile.getDisplayNameWithPipeline();
    final localizations = AppLocalizations.of(context);

    // Localize special display names
    String finalDisplayName = displayName;
    switch (displayName) {
      case 'DELETED_USER':
        finalDisplayName = localizations.translate('community-deleted-user');
        break;
      case 'ANONYMOUS_USER':
        finalDisplayName = localizations.translate('community-anonymous');
        break;
    }

    // Set reply state to show context in main reply input
    ref.read(replyStateProvider.notifier).startReply(
          commentId: comment.id,
          username: finalDisplayName,
        );

    // Scroll to bottom to show the reply input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showCompactCommentModal(BuildContext context, Comment comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompactCommentModal(
        comment: comment,
        onReplySubmitted: () {
          // Refresh comments when a new reply is submitted
          ref.refresh(postCommentsProvider(widget.postId));
        },
      ),
    );
  }

  void _showCommentReplyModalAfterSubmit(Comment parentComment) {
    // Use WidgetsBinding to ensure the UI has finished updating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) => CommentReplyModal(
            parentComment: parentComment,
            onReplySubmitted: () {
              // Refresh comments when a new reply is submitted in the modal
              ref.refresh(postCommentsProvider(widget.postId));
            },
          ),
        );
      }
    });
  }

  void _showCommentOptionsModal(Comment comment) {
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

      // Refresh the comments list
      ref.refresh(postCommentsProvider(widget.postId));

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
