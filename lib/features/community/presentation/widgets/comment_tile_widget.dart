import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/plus_badge_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_modal.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';

class CommentTileWidget extends ConsumerWidget {
  final Comment comment;
  final bool isAuthor;
  final VoidCallback? onMoreTap;

  const CommentTileWidget({
    super.key,
    required this.comment,
    this.isAuthor = false,
    this.onMoreTap,
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

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.grey[100]!,
              ),
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
                  avatarUrl: isAuthorAnonymous ? null : authorProfile.avatarUrl,
                  isPlusUser: isAuthorPlusUser,
                ),
              ),

              const SizedBox(width: 12),

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
                      comment.body,
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[800],
                        fontSize: 15,
                        height: 1.4,
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
    return Row(
      children: [
        // Username or anonymous indicator
        authorProfileAsync.when(
          data: (authorProfile) {
            final pipelineResult =
                authorProfile?.getDisplayNameWithPipeline() ?? 'Unknown User';

            final displayName =
                _getLocalizedDisplayName(pipelineResult, localizations);

            return GestureDetector(
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
                ),
              ),
            );
          },
          loading: () => Text(
            'Loading...',
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[700],
              fontSize: 14,
            ),
          ),
          error: (error, stackTrace) => Text(
            'Unknown User',
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[700],
              fontSize: 14,
            ),
          ),
        ),

        // Plus badge for Plus users
        if (isAuthorPlusUser) ...[
          const SizedBox(width: 6),
          const PlusBadgeWidget(
            fontSize: 9,
            iconSize: 8,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          ),
        ],

        // Real-time streak display for Plus users who allow sharing
        authorProfileAsync.when(
          data: (authorProfile) {
            if (isAuthorPlusUser && authorProfile.shareRelapseStreaks) {
              return Row(
                children: [
                  const SizedBox(width: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final streakAsync = ref.watch(
                          userStreakCalculatorProvider(comment.authorCPId));

                      return streakAsync.when(
                        data: (streakDays) {
                          if (streakDays == null || streakDays <= 0) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.trophy,
                                    size: 8, color: const Color(0xFF22C55E)),
                                const SizedBox(width: 2),
                                Text(
                                  '${streakDays}d',
                                  style: TextStyles.tiny.copyWith(
                                    color: const Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),

        // Author badge
        if (isAuthor) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ),
        ],

        const SizedBox(width: 8),

        // Timestamp
        Text(
          _formatTimestamp(comment.createdAt),
          style: TextStyles.caption.copyWith(
            color: theme.grey[500],
            fontSize: 12,
          ),
        ),

        const Spacer(),

        if (onMoreTap != null)
          GestureDetector(
            onTap: onMoreTap,
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: theme.grey[500],
            ),
          ),
      ],
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

        const Spacer(),
      ],
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
        CommunityInteractionGuard(
          onAccessGranted: isLoading ? () {} : () => _handleInteraction(ref),
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
