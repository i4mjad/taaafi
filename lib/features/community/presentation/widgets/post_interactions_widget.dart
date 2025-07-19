import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';

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

    // Watch optimistic post counts for immediate updates
    final optimisticPostState = ref.watch(optimisticPostStateProvider(post.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Like button with user state
          _UserInteractionButton(
            post: post,
            interactionValue: 1,
            icon: LucideIcons.thumbsUp,
            count: optimisticPostState.likeCount,
          ),

          const SizedBox(width: 24),

          // Dislike button with user state
          _UserInteractionButton(
            post: post,
            interactionValue: -1,
            icon: LucideIcons.thumbsDown,
            count: optimisticPostState.dislikeCount,
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
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    // Get current user's CP ID
    final currentUserCPId = currentProfileAsync.maybeWhen(
      data: (profile) => profile?.id ?? '',
      orElse: () => '',
    );

    // Watch optimistic user's interaction with this post (immediate feedback)
    final optimisticInteraction = ref.watch(
      optimisticUserInteractionProvider((
        targetType: 'post',
        targetId: post.id,
        userCPId: currentUserCPId,
      )),
    );

    final isActive = optimisticInteraction?.value == interactionValue;
    // No need to watch loading state since we have optimistic updates

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommunityInteractionGuard(
          onAccessGranted: () =>
              _handleOptimisticInteraction(ref, currentUserCPId),
          postId: post.id,
          userCPId: currentUserCPId,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? (interactionValue == 1
                      ? theme.primary[50]
                      : theme.error[50])
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? (interactionValue == 1
                      ? theme.primary[600]
                      : theme.error[600])
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

  void _handleOptimisticInteraction(WidgetRef ref, String currentUserCPId) {
    try {
      final optimisticInteraction = ref.read(
        optimisticUserInteractionProvider((
          targetType: 'post',
          targetId: post.id,
          userCPId: currentUserCPId,
        )),
      );

      // Determine new value based on current state
      final oldValue = optimisticInteraction?.value ?? 0;
      final newValue = oldValue == interactionValue ? 0 : interactionValue;

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
    } catch (e) {
      // Handle errors silently to prevent UI crashes
      debugPrint('Error handling optimistic interaction: $e');
    }
  }
}
