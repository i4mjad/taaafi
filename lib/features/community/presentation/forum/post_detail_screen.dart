import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_header_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_content_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_interactions_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_list_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/reply_input_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';
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

    return Scaffold(
      appBar: plainAppBar(context, ref, 'Thread', false, true),
      backgroundColor: theme.backgroundColor,
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return _buildPostNotFound(theme, localizations);
          }

          return Stack(
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
                                  _showPostOptions(context, post),
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
                        onShareTap: () => _sharePost(post),
                        onRepostTap: () => _repostPost(post),
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
                        onCommentMore: _handleCommentMore,
                      ),

                      // Add bottom padding to account for floating reply input
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Floating reply section
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
                      onReplySubmitted: _handleReplySubmitted,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(theme),
        error: (error, stack) => _buildErrorState(theme, localizations, error),
      ),
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
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.primary[600],
        ),
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

  void _sharePost(dynamic post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('share_coming_soon'),
        ),
      ),
    );
  }

  void _repostPost(dynamic post) {
    // TODO: Implement repost functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('repost_coming_soon'),
        ),
      ),
    );
  }

  void _handleCommentMore(Comment comment) {
    _showCommentOptions(context, comment);
  }

  void _handleReplySubmitted() {
    // Refresh comments when a new reply is submitted
    ref.refresh(postCommentsProvider(widget.postId));
  }

  void _showPostOptions(BuildContext context, dynamic post) {
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
              LucideIcons.chevronRight,
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

  void _showCommentOptions(BuildContext context, Comment comment) {
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
            _buildModalOption(
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
              _buildModalOption(
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

  void _showReportCommentModal(BuildContext context, Comment comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  void _showDeletePostConfirmation(BuildContext context, dynamic post) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('delete_post')),
        content: Text(localizations.translate('confirm_delete_post')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(context, post);
            },
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: theme.error[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentConfirmation(BuildContext context, Comment comment) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('delete_comment')),
        content: Text(localizations.translate('confirm_delete_comment')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteComment(context, comment);
            },
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: theme.error[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, dynamic post) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // TODO: Implement actual post deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('post_deleted')),
        backgroundColor: theme.success[500],
      ),
    );

    // Navigate back since the post is deleted
    Navigator.of(context).pop();
  }

  void _deleteComment(BuildContext context, Comment comment) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // TODO: Implement actual comment deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('comment_deleted')),
        backgroundColor: theme.success[500],
      ),
    );

    // Refresh comments to remove the deleted comment
    ref.refresh(postCommentsProvider(widget.postId));
  }
}
