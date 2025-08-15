import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/role_chip.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/streak_display_widget.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class CommentTileWidget extends ConsumerWidget {
  final Comment comment;
  final bool isAuthor;
  final VoidCallback? onMoreTap; // 3 dots - for comment options
  final VoidCallback? onCommentTap; // Comment body tap - for compact modal
  final VoidCallback? onReplyTap;
  final int nestingLevel;
  final bool isCondensed;

  const CommentTileWidget({
    super.key,
    required this.comment,
    this.isAuthor = false,
    this.onMoreTap,
    this.onCommentTap,
    this.onReplyTap,
    this.nestingLevel = 0,
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
            padding: EdgeInsets.only(
              left: 16 + (nestingLevel * 16.0), // Indent based on nesting level
              right: 16,
              top: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[100]!,
                ),
                left: nestingLevel > 0
                    ? BorderSide(
                        color: theme.grey[300]!,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
            ),
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
