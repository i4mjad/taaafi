import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class PostInteractionsWidget extends ConsumerWidget {
  final Post post;
  final int commentCount;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onRepostTap;

  const PostInteractionsWidget({
    super.key,
    required this.post,
    required this.commentCount,
    this.onCommentTap,
    this.onShareTap,
    this.onRepostTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Like button with user state
          _UserInteractionButton(
            post: post,
            interactionValue: 1,
            icon: LucideIcons.thumbsUp,
            count: post.likeCount,
          ),

          const SizedBox(width: 24),

          // Dislike button with user state
          _UserInteractionButton(
            post: post,
            interactionValue: -1,
            icon: LucideIcons.thumbsDown,
            count: post.dislikeCount,
          ),

          const SizedBox(width: 24),

          // Comment button
          _buildInteractionButton(
            theme,
            LucideIcons.messageCircle,
            false,
            onCommentTap,
          ),

          const SizedBox(width: 8),

          // Comment count
          Text(
            commentCount.toString(),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
            ),
          ),

          const SizedBox(width: 24),

          // Repost button
          _buildInteractionButton(
            theme,
            LucideIcons.repeat2,
            false,
            onRepostTap,
          ),

          const SizedBox(width: 24),

          // Share button
          _buildInteractionButton(
            theme,
            LucideIcons.share,
            false,
            onShareTap,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(
    dynamic theme,
    IconData icon,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? theme.primary[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? theme.primary[600] : theme.grey[500],
        ),
      ),
    );
  }
}

/// Separate widget to handle user interaction state
class _UserInteractionButton extends ConsumerWidget {
  final Post post;
  final int interactionValue;
  final IconData icon;
  final int count;

  const _UserInteractionButton({
    required this.post,
    required this.interactionValue,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    // Watch user's interaction with this post
    final userInteractionAsync = ref.watch(
      userInteractionProvider((
        targetType: 'post',
        targetId: post.id,
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
          onTap: isLoading ? null : () => _handleInteraction(ref),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? theme.primary[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
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
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
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
          targetType: 'post',
          targetId: post.id,
          userCPId: '',
        )),
      );

      userInteractionAsync.whenData((currentInteraction) {
        // If user already has this interaction, toggle it off (neutral)
        final newValue = currentInteraction?.value == interactionValue
            ? 0
            : interactionValue;

        // Trigger the interaction
        ref.read(postInteractionProvider(post.id).notifier).interact(newValue);
      });
    } catch (e) {
      // Handle errors silently to prevent UI crashes
      debugPrint('Error handling interaction: $e');
    }
  }
}
