import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/plus_badge_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/streak_display_widget.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
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
    final categoriesAsync = ref.watch(postCategoriesProvider);

    // Find the matching category for the post
    final postCategory = categoriesAsync.maybeWhen(
      data: (categories) {
        try {
          return categories.firstWhere(
            (category) => category.id == post.category,
          );
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );

    return authorProfileAsync.when(
      data: (authorProfile) {
        final isAuthorAnonymous = authorProfile?.isAnonymous ?? false;
        final isAuthorPlusUser = authorProfile?.hasPlusSubscription() ?? false;

        return Row(
          children: [
            // User avatar
            AvatarWithAnonymity(
              cpId: post.authorCPId,
              isAnonymous: isAuthorAnonymous,
              size: 40,
              avatarUrl: isAuthorAnonymous ? null : authorProfile?.avatarUrl,
              isPlusUser: isAuthorPlusUser,
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

                  // Category and timestamp row
                  Row(
                    children: [
                      // Category flair - show category or fallback
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: postCategory != null
                              ? postCategory.color.withValues(alpha: 0.1)
                              : theme.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: postCategory != null
                                ? postCategory.color.withValues(alpha: 0.3)
                                : theme.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              postCategory?.icon ?? LucideIcons.tag,
                              size: 12,
                              color: postCategory?.color ?? theme.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              postCategory?.getDisplayName(
                                    localizations.locale.languageCode,
                                  ) ??
                                  _getLocalizedCategoryName(
                                      post.category, localizations),
                              style: TextStyles.small.copyWith(
                                color: postCategory?.color ?? theme.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Plus badge if user is a Plus user
                      if (isAuthorPlusUser) ...[
                        const SizedBox(width: 6),
                        const PlusBadgeWidget(),
                      ],

                      // Streak display if user shares streak info
                      if (authorProfile?.hasValidStreakData() == true) ...[
                        const SizedBox(width: 6),
                        StreakDisplayWidget(
                          streakDays: authorProfile!.currentStreakDays!,
                        ),
                      ],

                      const SizedBox(width: 8),

                      // Timestamp
                      Text(
                        _formatTimestamp(post.createdAt, localizations),
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[600],
                        ),
                      ),
                    ],
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

  /// Get localized category name for fallback cases
  String _getLocalizedCategoryName(
      String categoryId, AppLocalizations localizations) {
    // Handle common category fallbacks with localization
    switch (categoryId.toLowerCase()) {
      case 'general':
        return localizations.translate('community_general');
      case 'discussion':
        return localizations.translate('community_discussion');
      case 'question':
        return localizations.translate('community_question');
      case 'help':
        return localizations.translate('community_help');
      case 'news':
        return localizations.translate('community_news');
      default:
        // Fallback to the original category ID if no translation is available
        return categoryId;
    }
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
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return localizations
          .translate('time-hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return localizations
          .translate('time-minutes-ago')
          .replaceAll('{count}', difference.inMinutes.toString());
    } else {
      return localizations.translate('time-now');
    }
  }
}
