import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_tile_widget.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class CommentListWidget extends ConsumerWidget {
  final String postId;
  final String postAuthorCPId;
  final Function(Comment)? onCommentMore;

  const CommentListWidget({
    super.key,
    required this.postId,
    required this.postAuthorCPId,
    this.onCommentMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final commentsAsync = ref.watch(postCommentsProvider(postId));

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return _buildEmptyState(theme, localizations);
        }

        // Use ListView.builder instead of Column to prevent overflow
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return CommentTileWidget(
              comment: comment,
              isAuthor: comment.authorCPId == postAuthorCPId,
              onMoreTap:
                  onCommentMore != null ? () => onCommentMore!(comment) : null,
            );
          },
        );
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stackTrace) =>
          _buildErrorState(theme, localizations, error),
    );
  }

  Widget _buildEmptyState(dynamic theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: theme.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_comments_yet'),
            style: TextStyles.bodyLarge.copyWith(
              color: theme.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('be_first_to_comment'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Spinner(
          valueColor: theme.primary[600],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    dynamic theme,
    AppLocalizations localizations,
    Object error,
  ) {
    print('❌ Error loading comments: $error');
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.error[500],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('error_loading_comments'),
            style: TextStyles.bodyLarge.copyWith(
              color: theme.error[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
