import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    return currentProfileAsync.when(
      data: (currentProfile) {
        final isAnonymous = currentProfile?.isAnonymous ?? false;

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
              // User avatar
              AvatarWithAnonymity(
                cpId: comment.authorCPId,
                isAnonymous: isAnonymous,
                size: 32,
              ),

              const SizedBox(width: 12),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info and timestamp
                    _buildUserInfo(theme, localizations, isAnonymous),

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
                    _buildActionsRow(theme, localizations, ref),
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
      dynamic theme, AppLocalizations localizations, bool isAnonymous) {
    return Row(
      children: [
        // Username or anonymous indicator
        Text(
          isAnonymous
              ? localizations.translate('anonymous')
              : 'User ${comment.authorCPId}', // TODO: Replace with actual username
          style: TextStyles.footnoteSelected.copyWith(
            color: theme.grey[700],
            fontSize: 14,
          ),
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

  Widget _buildActionsRow(
      dynamic theme, AppLocalizations localizations, WidgetRef ref) {
    return Row(
      children: [
        // Like button
        _buildInteractionButton(
          theme,
          LucideIcons.heart,
          comment.score > 0,
          () => _handleLike(ref, 1),
        ),

        const SizedBox(width: 16),

        // Comment count/score display
        Text(
          '${comment.score} ${localizations.translate('likes')}',
          style: TextStyles.tiny.copyWith(
            color: theme.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),

        const SizedBox(width: 16),

        // Dislike button
        _buildInteractionButton(
          theme,
          LucideIcons.heartOff,
          comment.score < 0,
          () => _handleLike(ref, -1),
        ),

        const Spacer(),
      ],
    );
  }

  Widget _buildInteractionButton(
    dynamic theme,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
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
          size: 18,
          color: isActive ? theme.primary[600] : theme.grey[500],
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

  void _handleLike(WidgetRef ref, int value) {
    ref.read(commentVoteProvider(comment.id).notifier).vote(value);
  }
}
