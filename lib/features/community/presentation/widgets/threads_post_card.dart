import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_modal.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/streak_display_widget.dart';

class ThreadsPostCard extends ConsumerWidget {
  final Post post;
  final VoidCallback? onTap;

  const ThreadsPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(post.authorCPId));
    final categoriesAsync = ref.watch(postCategoriesProvider);

    // Get current user's CP ID
    final currentUserCPId = currentProfileAsync.maybeWhen(
      data: (profile) => profile?.id ?? '',
      orElse: () => '',
    );

    // Watch optimistic user's interaction with this post (immediate feedback)
    final optimisticInteractionAsync = ref.watch(
      optimisticUserInteractionProvider((
        targetType: 'post',
        targetId: post.id,
        userCPId: currentUserCPId,
      )),
    );

    // Watch optimistic post counts (immediate count updates)
    final optimisticPostState = ref.watch(optimisticPostStateProvider(post.id));

    // If post is optimistically deleted, don't render it
    if (optimisticPostState.isDeleted) {
      return const SizedBox.shrink();
    }

    // Find the matching category for the post
    final postCategory = categoriesAsync.maybeWhen(
      data: (categories) {
        try {
          return categories.firstWhere(
            (category) => category.id == post.category,
          );
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.grey[100]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with proper author anonymity
              authorProfileAsync.when(
                data: (authorProfile) {
                  final isAuthorAnonymous = authorProfile?.isAnonymous ?? false;
                  final isAuthorPlusUser =
                      authorProfile?.hasPlusSubscription() ?? false;
                  final isOrphanedPost =
                      authorProfile?.userUID == 'orphaned-post';

                  final isAvatarTappable =
                      !isOrphanedPost && !isAuthorAnonymous;

                  if (isAvatarTappable) {
                    return InkWell(
                      onTap: () => _showCommunityProfileModal(
                        context,
                        post.authorCPId,
                        authorProfile?.displayName ?? 'Unknown User',
                        authorProfile?.avatarUrl,
                        isAuthorAnonymous,
                        isAuthorPlusUser,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: AvatarWithAnonymity(
                        cpId: post.authorCPId,
                        isAnonymous: isAuthorAnonymous,
                        size: 32,
                        avatarUrl:
                            isAuthorAnonymous ? null : authorProfile?.avatarUrl,
                        isPlusUser: isAuthorPlusUser,
                      ),
                    );
                  } else {
                    return AvatarWithAnonymity(
                      cpId: post.authorCPId,
                      isAnonymous: isAuthorAnonymous,
                      size: 32,
                      avatarUrl:
                          isAuthorAnonymous ? null : authorProfile?.avatarUrl,
                      isPlusUser: isAuthorPlusUser,
                    );
                  }
                },
                loading: () => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                error: (error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.error[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 16,
                    color: theme.error[500],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category flair and time
                      Row(
                        children: [
                          // Category and streak in an inline layout
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // Category flair - always show, with fallback for missing categories
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: postCategory != null
                                      ? postCategory.color
                                          .withValues(alpha: 0.1)
                                      : theme.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: postCategory != null
                                        ? postCategory.color
                                            .withValues(alpha: 0.3)
                                        : theme.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      postCategory?.icon ?? LucideIcons.tag,
                                      size: 12,
                                      color: postCategory?.color ??
                                          theme.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      postCategory?.getDisplayName(
                                            localizations.locale.languageCode,
                                          ) ??
                                          _getLocalizedCategoryName(
                                              post.category, localizations),
                                      style: TextStyles.small.copyWith(
                                        color: postCategory?.color ??
                                            theme.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Real-time streak badge
                              ...() {
                                return authorProfileAsync.maybeWhen(
                                  data: (authorProfile) {
                                    // Check if user is plus AND allows sharing
                                    final isPlusUser =
                                        authorProfile?.hasPlusSubscription() ??
                                            false;
                                    final allowsSharing =
                                        authorProfile?.shareRelapseStreaks ??
                                            false;

                                    if (!isPlusUser || !allowsSharing) {
                                      return <Widget>[];
                                    }

                                    // Calculate streak in real-time
                                    return [
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final streakAsync = ref.watch(
                                              userStreakCalculatorProvider(
                                                  post.authorCPId));

                                          return streakAsync.when(
                                            data: (streakDays) {
                                              if (streakDays == null ||
                                                  streakDays <= 0) {
                                                return const SizedBox.shrink();
                                              }

                                              return StreakDisplayWidget(
                                                streakDays: streakDays,
                                              );
                                            },
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (error, stackTrace) {
                                              return const SizedBox.shrink();
                                            },
                                          );
                                        },
                                      ),
                                    ];
                                  },
                                  orElse: () => <Widget>[],
                                );
                              }(),
                            ],
                          ),

                          const Spacer(),

                          Text(
                            _formatTimeAgo(post.createdAt, localizations),
                            style: TextStyles.small.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showPostOptionsModal(context, ref),
                            child: Icon(
                              LucideIcons.moreHorizontal,
                              color: theme.grey[900],
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Post title
                      Text(
                        post.title,
                        style: TextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Post content
                      Text(
                        post.body,
                        style: TextStyles.body.copyWith(
                          color: theme.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Interaction buttons
                      Row(
                        children: [
                          // Like button
                          Builder(
                            builder: (context) {
                              final interaction = optimisticInteractionAsync;
                              final isLiked = interaction?.value == 1;
                              return CommunityInteractionGuard(
                                onAccessGranted: () =>
                                    _handleOptimisticInteraction(
                                        ref, 1, interaction, currentUserCPId),
                                postId: post.id,
                                userCPId: currentUserCPId,
                                child: _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsUp,
                                  isLiked,
                                  null, // No onTap since it's handled by guard
                                  activeColor: const Color(
                                      0xFF10B981), // Green color for likes
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 4),

                          Text(
                            optimisticPostState.likeCount.toString(),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Dislike button
                          Builder(
                            builder: (context) {
                              final interaction = optimisticInteractionAsync;
                              final isDisliked = interaction?.value == -1;
                              return CommunityInteractionGuard(
                                onAccessGranted: () =>
                                    _handleOptimisticInteraction(
                                        ref, -1, interaction, currentUserCPId),
                                postId: post.id,
                                userCPId: currentUserCPId,
                                child: _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsDown,
                                  isDisliked,
                                  null, // No onTap since it's handled by guard
                                  activeColor: const Color(
                                      0xFFEF4444), // Red color for dislikes
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 4),

                          Text(
                            optimisticPostState.dislikeCount.toString(),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Comment button
                          _buildEngagementButton(
                            theme,
                            LucideIcons.messageCircle,
                            false,
                            null,
                          ),

                          const SizedBox(width: 4),

                          // Comment count
                          Consumer(
                            builder: (context, ref, child) {
                              final commentCountAsync =
                                  ref.watch(postCommentCountProvider(post.id));
                              return commentCountAsync.when(
                                data: (count) => Text(
                                  count.toString(),
                                  style: TextStyles.caption.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                                loading: () => Text(
                                  '0',
                                  style: TextStyles.caption.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                                error: (error, stack) => Text(
                                  '0',
                                  style: TextStyles.caption.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton(
    dynamic theme,
    IconData icon,
    bool isActive,
    VoidCallback? onTap, {
    Color? activeColor,
  }) {
    final effectiveActiveColor = activeColor ?? theme.primary[600];
    final activeBackgroundColor = activeColor != null
        ? activeColor.withValues(alpha: 0.1)
        : theme.primary[50];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? activeBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? effectiveActiveColor : theme.grey[600],
        ),
      ),
    );
  }

  void _handleOptimisticInteraction(WidgetRef ref, int value,
      Interaction? interaction, String currentUserCPId) {
    final oldValue = interaction?.value ?? 0;
    final newValue = oldValue == value ? 0 : value;

    // 1. Immediately update interaction UI (optimistic)
    ref
        .read(optimisticUserInteractionProvider((
          targetType: 'post',
          targetId: post.id,
          userCPId: currentUserCPId,
        )).notifier)
        .updateOptimistically(newValue);

    // 2. Immediately update counts UI (optimistic)
    ref
        .read(optimisticPostStateProvider(post.id).notifier)
        .updateOptimisticCounts(oldValue, newValue);

    // 3. Process actual interaction (this will check for bans)
    ref.read(postInteractionProvider(post.id).notifier).interact(newValue);
  }

  String _formatTimeAgo(DateTime createdAt, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return localizations
          .translate('time-days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return localizations
          .translate('time-hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return localizations
          .translate('time-minutes-ago')
          .replaceAll('{count}', difference.inMinutes.toString());
    } else {
      return localizations.translate('time-now');
    }
  }

  /// Get localized category name for fallback cases
  String _getLocalizedCategoryName(
      String categoryId, AppLocalizations localizations) {
    // Handle common category fallbacks with localization
    switch (categoryId.toLowerCase()) {
      case 'general':
        return localizations.translate('community_general');
      case 'discussion':
        return localizations.translate('community_discussion');
      case 'question':
        return localizations.translate('community_question');
      case 'help':
        return localizations.translate('community_help');
      case 'news':
        return localizations.translate('community_news');
      default:
        // Fallback to the original category ID if no translation is available
        return categoryId;
    }
  }

  void _showPostOptionsModal(BuildContext context, WidgetRef ref) {
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
        // margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.only(
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
                _reportPost(context, ref);
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
                  _toggleCommenting(context, ref);
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
                  _deletePost(context, ref);
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

  void _reportPost(BuildContext context, WidgetRef ref) {
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

  void _toggleCommenting(BuildContext context, WidgetRef ref) async {
    try {
      // Use the repository to toggle commenting
      await ref.read(forumRepositoryProvider).togglePostCommenting(
            postId: post.id,
            isCommentingAllowed: !post.isCommentingAllowed,
          );

      // Show success message only if context is still valid
      if (context.mounted) {
        final messageKey = post.isCommentingAllowed
            ? 'commenting_disabled'
            : 'commenting_enabled';
        getSuccessSnackBar(context, messageKey);
      }
    } catch (e) {
      // Show error message only if context is still valid
      if (context.mounted) {
        getErrorSnackBar(context, 'error_toggle_commenting');
      }
    }
  }

  void _deletePost(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.error[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
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
                    const SizedBox(height: 12),
                    Text(
                      localizations.translate('delete_post'),
                      style: TextStyles.h6.copyWith(
                        color: theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  localizations.translate('confirm_delete_post'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.grey[100],
                            borderRadius: BorderRadius.circular(8),
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
                        onTap: () async {
                          Navigator.of(context).pop();

                          // Mark as deleted optimistically for immediate UI feedback
                          ref
                              .read(
                                  optimisticPostStateProvider(post.id).notifier)
                              .markAsDeleted();

                          // Show brief success message
                          if (context.mounted) {
                            getSuccessSnackBar(context, 'post_deleted');
                          }

                          try {
                            // Perform actual deletion in background
                            await ref
                                .read(forumRepositoryProvider)
                                .deletePost(post.id);
                          } catch (e) {
                            // Revert optimistic deletion if failed
                            ref
                                .read(optimisticPostStateProvider(post.id)
                                    .notifier)
                                .revertDeletion();

                            // Show error message only if context is still valid
                            if (context.mounted) {
                              getErrorSnackBar(context, 'error_deleting_post');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.error[500],
                            borderRadius: BorderRadius.circular(8),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Show community profile modal
  void _showCommunityProfileModal(
    BuildContext context,
    String communityProfileId,
    String displayName,
    String? avatarUrl,
    bool isAnonymous,
    bool isPlusUser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommunityProfileModal(
          communityProfileId: communityProfileId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          isAnonymous: isAnonymous,
          isPlusUser: isPlusUser,
        ),
      ),
    );
  }
}
