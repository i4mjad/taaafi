import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/streak_display_widget.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_modal.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

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

  /// Helper function to localize special display name constants
  String _getLocalizedDisplayName(
      String displayName, AppLocalizations localizations) {
    switch (displayName) {
      case 'DELETED_USER':
        final localized = localizations.translate('community-deleted-user');
        return localized;
      case 'ANONYMOUS_USER':
        final localized = localizations.translate('community-anonymous');
        return localized;
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
        ref.watch(communityProfileByIdProvider(post.authorCPId));
    final categoriesAsync = ref.watch(allPostCategoriesProvider);

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
        final isAuthorAnonymous = authorProfile.isAnonymous;
        final isAuthorPlusUser = authorProfile.hasPlusSubscription();
        final isOrphanedPost = authorProfile.userUID == 'orphaned-post';

        return Row(
          children: [
            // User avatar - clickable to show profile
            GestureDetector(
              onTap: () => _showCommunityProfileModal(
                context,
                post.authorCPId,
                authorProfile.displayName,
                authorProfile.avatarUrl,
                isAuthorAnonymous,
                isAuthorPlusUser,
              ),
              child: AvatarWithAnonymity(
                isDeleted: authorProfile.isDeleted,
                cpId: post.authorCPId,
                isAnonymous: isAuthorAnonymous,
                size: 40,
                avatarUrl: isAuthorAnonymous ? null : authorProfile.avatarUrl,
                isPlusUser: isAuthorPlusUser,
              ),
            ),

            const SizedBox(width: 12),

            // User info and timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Author name and metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Display name with role icon - clickable to show profile
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => _showCommunityProfileModal(
                                      context,
                                      post.authorCPId,
                                      authorProfile.displayName,
                                      authorProfile.avatarUrl,
                                      isAuthorAnonymous,
                                      isAuthorPlusUser,
                                    ),
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Role icon (only show for founder and admin)
                                          if (authorProfile.role
                                                      .toLowerCase() ==
                                                  'founder' ||
                                              authorProfile.role
                                                      .toLowerCase() ==
                                                  'admin') ...[
                                            () {
                                              final roleData = _getRoleIconData(
                                                  authorProfile.role
                                                      .toLowerCase());
                                              return Icon(
                                                roleData.icon,
                                                size: 16,
                                                color: roleData.color,
                                              );
                                            }(),
                                            const SizedBox(width: 4),
                                          ],
                                          Flexible(
                                            child: Text(
                                              () {
                                                final pipelineResult = authorProfile
                                                    .getDisplayNameWithPipeline();

                                                final localizedResult =
                                                    _getLocalizedDisplayName(
                                                        pipelineResult,
                                                        localizations);

                                                return localizedResult;
                                              }(),
                                              style: TextStyles.body.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: () {
                                                  if (isOrphanedPost) {
                                                    return theme.grey[
                                                        600]; // Dimmed for orphaned posts
                                                  }
                                                  // Apply role color for founder/admin
                                                  if (authorProfile.role
                                                              .toLowerCase() ==
                                                          'founder' ||
                                                      authorProfile.role
                                                              .toLowerCase() ==
                                                          'admin') {
                                                    final roleData =
                                                        _getRoleIconData(
                                                            authorProfile.role
                                                                .toLowerCase());
                                                    return roleData.color;
                                                  }
                                                  // Default color logic
                                                  return !isAuthorAnonymous
                                                      ? theme.primary[700]
                                                      : theme.grey[900];
                                                }(),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 4),
                                Text(
                                  '•',
                                  style: TextStyles.h6.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Timestamp
                                Text(
                                  _formatTimestamp(
                                      post.createdAt, localizations),
                                  style: TextStyles.caption.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),

                            // Category chip and streak display in a wrapping row
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      // Category chip
                                      WidgetsContainer(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        backgroundColor: postCategory?.color
                                                .withValues(alpha: 0.1) ??
                                            theme.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: postCategory?.color
                                                  .withValues(alpha: 0.3) ??
                                              theme.grey[300]!,
                                          width: 1,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              postCategory?.icon ??
                                                  LucideIcons.tag,
                                              size: 12,
                                              color: postCategory?.color ??
                                                  theme.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              postCategory?.getDisplayName(
                                                    localizations
                                                        .locale.languageCode,
                                                  ) ??
                                                  _getLocalizedCategoryName(
                                                      post.category,
                                                      localizations),
                                              style: TextStyles.small.copyWith(
                                                color: postCategory?.color ??
                                                    theme.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Streak display if user shares streak info
                                      ...() {
                                        return authorProfileAsync.maybeWhen(
                                          data: (authorProfile) {
                                            // Check if user is plus AND allows sharing
                                            final isPlusUser = authorProfile
                                                .hasPlusSubscription();
                                            final allowsSharing = authorProfile
                                                .shareRelapseStreaks;

                                            if (!isPlusUser || !allowsSharing) {
                                              return <Widget>[];
                                            }

                                            // Calculate streak in real-time
                                            return [
                                              Consumer(
                                                builder: (context, ref, child) {
                                                  final streakAsync = ref.watch(
                                                      userStreakCalculatorProvider(
                                                          post.authorCPId));

                                                  return streakAsync.when(
                                                    data: (streakDays) {
                                                      if (streakDays == null ||
                                                          streakDays <= 0) {
                                                        return const SizedBox
                                                            .shrink();
                                                      }

                                                      return StreakDisplayWidget(
                                                        streakDays: streakDays,
                                                      );
                                                    },
                                                    loading: () =>
                                                        const SizedBox.shrink(),
                                                    error: (error, stackTrace) {
                                                      return const SizedBox
                                                          .shrink();
                                                    },
                                                  );
                                                },
                                              ),
                                            ];
                                          },
                                          orElse: () => <Widget>[],
                                        );
                                      }(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
      case 'aqohcyog1z8tcij0y1s4': // News category ID (lowercase)
      case 'aqOhcyOg1z8tcij0y1S4': // News category ID (original case)
        return localizations.translate('community_news');
      default:
        // Fallback to the original category ID if no translation is available
        return categoryId;
    }
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

  /// Show community profile modal
  void _showCommunityProfileModal(
    BuildContext context,
    String communityProfileId,
    String displayName,
    String? avatarUrl,
    bool isAnonymous,
    bool isPlusUser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommunityProfileModal(
          communityProfileId: communityProfileId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          isAnonymous: isAnonymous,
          isPlusUser: isPlusUser,
        ),
      ),
    );
  }

  /// Get role icon and color data based on role
  _RoleIconData _getRoleIconData(String role) {
    switch (role) {
      case 'admin':
        return _RoleIconData(
          icon: LucideIcons.shield,
          color: const Color(0xFF2563EB), // Blue color for admin
        );
      case 'founder':
        return _RoleIconData(
          icon: LucideIcons.personStanding,
          color: const Color(0xFF7C3AED), // Purple color for founder
        );
      case 'member':
      default:
        return _RoleIconData(
          icon: LucideIcons.user,
          color: const Color(0xFF6B7280), // Gray color for member
        );
    }
  }
}

/// Data class for role icon information
class _RoleIconData {
  final IconData icon;
  final Color color;

  const _RoleIconData({
    required this.icon,
    required this.color,
  });
}
