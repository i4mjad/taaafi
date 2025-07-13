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
          // Like button
          _buildInteractionButton(
            theme,
            LucideIcons.heart,
            post.score > 0,
            () => _handleLike(ref, 1),
          ),

          const SizedBox(width: 16),

          // Score display
          Text(
            '${post.score} ${localizations.translate('likes')}',
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
            ),
          ),

          const SizedBox(width: 16),

          // Dislike button
          _buildInteractionButton(
            theme,
            LucideIcons.heartOff,
            post.score < 0,
            () => _handleLike(ref, -1),
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
    ref.read(postVoteProvider(post.id).notifier).vote(value);
  }
}
