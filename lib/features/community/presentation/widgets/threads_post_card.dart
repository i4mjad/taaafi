import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

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

    // Watch user's interaction with this post
    final userInteractionAsync = ref.watch(
      userInteractionProvider((
        targetType: 'post',
        targetId: post.id,
        userCPId: '', // Will be filled by provider
      )),
    );

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
                          Icon(
                            Icons.more_horiz,
                            color: theme.grey[400],
                            size: 16,
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
                          userInteractionAsync.when(
                            data: (interaction) {
                              final isLiked = interaction?.value == 1;
                              return _buildEngagementButton(
                                theme,
                                LucideIcons.thumbsUp,
                                isLiked,
                                () => _handleInteraction(
                                    ref, 1, interaction?.value),
                                activeColor: const Color(
                                    0xFF10B981), // Green color for likes
                              );
                            },
                            loading: () => _buildEngagementButton(
                              theme,
                              LucideIcons.thumbsUp,
                              false,
                              null,
                            ),
                            error: (error, stackTrace) =>
                                _buildEngagementButton(
                              theme,
                              LucideIcons.thumbsUp,
                              false,
                              null,
                            ),
                          ),

                          const SizedBox(width: 4),

                          Text(
                            post.likeCount.toString(),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Dislike button
                          userInteractionAsync.when(
                            data: (interaction) {
                              final isDisliked = interaction?.value == -1;
                              return _buildEngagementButton(
                                theme,
                                LucideIcons.thumbsDown,
                                isDisliked,
                                () => _handleInteraction(
                                    ref, -1, interaction?.value),
                                activeColor: const Color(
                                    0xFFEF4444), // Red color for dislikes
                              );
                            },
                            loading: () => _buildEngagementButton(
                              theme,
                              LucideIcons.thumbsDown,
                              false,
                              null,
                            ),
                            error: (error, stackTrace) =>
                                _buildEngagementButton(
                              theme,
                              LucideIcons.thumbsDown,
                              false,
                              null,
                            ),
                          ),

                          const SizedBox(width: 4),

                          Text(
                            post.dislikeCount.toString(),
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

  void _handleInteraction(WidgetRef ref, int value, int? currentValue) {
    // Determine the new interaction value based on current state
    int newValue;

    if (currentValue == value) {
      // If clicking the same action, toggle it off (neutral)
      newValue = 0;
    } else {
      // If clicking different action or no current action, set to new value
      newValue = value;
    }

    // Trigger the interaction
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
}
