import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';

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

    // No need to watch interaction loading state since we have optimistic updates

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    final isAuthorAnonymous =
                        authorProfile?.isAnonymous ?? false;
                    return AvatarWithAnonymity(
                      cpId: post.authorCPId,
                      isAnonymous: isAuthorAnonymous,
                      size: 32,
                      avatarUrl:
                          isAuthorAnonymous ? null : authorProfile?.avatarUrl,
                    );
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

                // User info and content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and time
                      Row(
                        children: [
                          // Author name with proper error handling
                          Expanded(
                            child: authorProfileAsync.when(
                              data: (authorProfile) {
                                final isAuthorAnonymous =
                                    authorProfile?.isAnonymous ?? false;
                                final displayName = isAuthorAnonymous
                                    ? localizations.translate('anonymous')
                                    : authorProfile?.displayName ??
                                        localizations.translate('unknown_user');

                                return Text(
                                  displayName,
                                  style: TextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.grey[900],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                              loading: () => Container(
                                height: 16,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: theme.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              error: (error, stackTrace) => Text(
                                localizations.translate('unknown_user'),
                                style: TextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.error[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(post.createdAt, localizations),
                            style: TextStyles.caption.copyWith(
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

                          Text(
                            '0', // TODO: Add comment count
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),

                          const Spacer(),

                          // Share button
                          _buildEngagementButton(
                            theme,
                            LucideIcons.share,
                            false,
                            null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
          .replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return localizations
          .translate('time-hours-ago')
          .replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return localizations
          .translate('time-minutes-ago')
          .replaceAll('{count}', difference.inMinutes.toString());
    } else {
      return localizations.translate('time-now');
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
              LucideIcons.chevronRight,
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

  void _deletePost(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Show confirmation dialog
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
              // TODO: Implement actual deletion logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('post_deleted')),
                  backgroundColor: theme.success[500],
                ),
              );
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
}
