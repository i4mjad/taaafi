import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';

class PostHeaderWidget extends ConsumerWidget {
  final Post post;
  final bool showAuthorBadge;
  final VoidCallback? onMorePressed;

  const PostHeaderWidget({
    super.key,
    required this.post,
    this.showAuthorBadge = false,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(post.authorCPId));

    return authorProfileAsync.when(
      data: (authorProfile) {
        final isAuthorAnonymous = authorProfile?.isAnonymous ?? false;

        return Row(
          children: [
            // User avatar
            AvatarWithAnonymity(
              cpId: post.authorCPId,
              isAnonymous: isAuthorAnonymous,
              size: 40,
              avatarUrl: isAuthorAnonymous ? null : authorProfile?.avatarUrl,
            ),

            const SizedBox(width: 12),

            // User info and timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Display name or anonymous
                      Expanded(
                        child: Text(
                          isAuthorAnonymous
                              ? localizations.translate('anonymous')
                              : authorProfile?.displayName ?? 'Unknown User',
                          style: TextStyles.body.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Author badge if this is the post author
                      if (showAuthorBadge &&
                          _isCurrentUserAuthor(
                              ref.watch(currentCommunityProfileProvider))) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            localizations.translate('author'),
                            style: TextStyles.tiny.copyWith(
                              color: theme.primary[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Timestamp
                  Text(
                    _formatTimestamp(post.createdAt, localizations),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // More actions button
            if (onMorePressed != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onMorePressed,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.moreHorizontal,
                    size: 20,
                    color: theme.grey[600],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stackTrace) =>
          _buildErrorState(theme, localizations, error),
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState(dynamic theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
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
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: theme.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build error state widget
  Widget _buildErrorState(
      dynamic theme, AppLocalizations localizations, Object error) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 40,
          color: theme.error[500],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            localizations.translate('error_loading_profile'),
            style: TextStyles.body.copyWith(
              color: theme.error[600],
            ),
          ),
        ),
      ],
    );
  }

  /// Check if current user is the author of this post
  bool _isCurrentUserAuthor(
      AsyncValue<CommunityProfileEntity?> currentProfileAsync) {
    return currentProfileAsync.maybeWhen(
      data: (profile) => profile?.id == post.authorCPId,
      orElse: () => false,
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
