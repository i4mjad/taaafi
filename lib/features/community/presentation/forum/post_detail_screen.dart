import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_header_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_content_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_interactions_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_list_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/reply_input_widget.dart';
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
              // Main content
              Column(
                children: [
                  // Post content
                  Expanded(
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
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
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
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('post_not_found_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
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
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.error[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: Text(
                AppLocalizations.of(context).translate('report_post'),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentOptions(BuildContext context, Comment comment) {
    final theme = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: theme.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).translate('comment-settings'),
                  style: TextStyles.h6,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            verticalSpace(Spacing.points8),
            WidgetsContainer(
              backgroundColor: theme.warn[50],
              borderSide: BorderSide(
                color: theme.warn[500]!,
                width: 1,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.report_outlined,
                    color: theme.warn[700],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate('report_comment'),
                    style: TextStyles.caption.copyWith(
                      color: theme.warn[700],
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points8),
            WidgetsContainer(
              backgroundColor: theme.error[50],
              borderSide: BorderSide(
                color: theme.error[500]!,
                width: 1,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.trash,
                    color: theme.error[700],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate('delete-comment'),
                    style: TextStyles.caption.copyWith(
                      color: theme.error[700],
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
}
