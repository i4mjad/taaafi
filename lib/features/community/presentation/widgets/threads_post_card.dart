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

    // Watch user's interaction with this post
    final userInteractionAsync = ref.watch(
      userInteractionProvider((
        targetType: 'post',
        targetId: post.id,
        userCPId: '', // Will be filled by provider
      )),
    );

    return currentProfileAsync.when(
      data: (currentProfile) {
        final isAnonymous = currentProfile?.isAnonymous ?? false;

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
                    // Avatar
                    AvatarWithAnonymity(
                      cpId: post.authorCPId,
                      isAnonymous: isAnonymous,
                      size: 32,
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
                              Text(
                                post.title,
                                style: TextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.grey[900],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeAgo(post.createdAt, localizations),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[500],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.more_horiz,
                                color: theme.grey[400],
                                size: 16,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Post content
                          Text(
                            post.body,
                            style: TextStyles.body.copyWith(
                              color: theme.grey[900],
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Engagement buttons (like/dislike)
                          userInteractionAsync.when(
                            data: (interaction) => Row(
                              children: [
                                // Like button
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsUp,
                                  interaction?.value == 1,
                                  () => _handleLike(ref, 1),
                                ),
                                horizontalSpace(Spacing.points4),

                                // Like count
                                Text(
                                  '${post.likeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                horizontalSpace(Spacing.points8),

                                // Dislike button
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsDown,
                                  interaction?.value == -1,
                                  () => _handleLike(ref, -1),
                                ),
                                horizontalSpace(Spacing.points4),

                                // Dislike count
                                Text(
                                  '${post.dislikeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                horizontalSpace(Spacing.points8),

                                // Comment button
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.messageCircle,
                                  false,
                                  () {
                                    // Handle comment
                                  },
                                ),
                              ],
                            ),
                            loading: () => Row(
                              children: [
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsUp,
                                  false,
                                  null,
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  '${post.likeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                horizontalSpace(Spacing.points8),
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsDown,
                                  false,
                                  null,
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  '${post.dislikeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => Row(
                              children: [
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsUp,
                                  false,
                                  () => _handleLike(ref, 1),
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  '${post.likeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                horizontalSpace(Spacing.points8),
                                _buildEngagementButton(
                                  theme,
                                  LucideIcons.thumbsDown,
                                  false,
                                  () => _handleLike(ref, -1),
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  '${post.dislikeCount}',
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Engagement stats
                          Text(
                            '${post.likeCount} ${localizations.translate('likes')} · ${post.dislikeCount} ${localizations.translate('dislikes')}',
                            style: TextStyles.tiny.copyWith(
                              color: theme.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
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
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stackTrace) =>
          _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildLoadingState(dynamic theme) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.grey[100]!,
            width: 0.5,
          ),
        ),
      ),
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
              localizations.translate('error_loading_post'),
              style: TextStyles.body.copyWith(
                color: theme.error[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton(
    dynamic theme,
    IconData icon,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? theme.primary[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? theme.primary[600] : theme.grey[600],
        ),
      ),
    );
  }

  void _handleLike(WidgetRef ref, int value) {
    // Get current user's interaction
    final userInteractionAsync = ref.read(
      userInteractionProvider((
        targetType: 'post',
        targetId: post.id,
        userCPId: '', // Will be filled by provider
      )),
    );

    userInteractionAsync.whenData((currentInteraction) {
      // If user already has this interaction, toggle it off (neutral)
      final newValue = currentInteraction?.value == value ? 0 : value;

      // Trigger the interaction
      ref.read(postInteractionProvider(post.id).notifier).interact(newValue);
    });
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
