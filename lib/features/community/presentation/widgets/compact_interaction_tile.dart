import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';

class CompactInteractionTile extends ConsumerWidget {
  final dynamic item; // Can be Post or Comment
  final bool isLikedPost;

  const CompactInteractionTile({
    super.key,
    required this.item,
    required this.isLikedPost,
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

    if (isLikedPost) {
      return _buildLikedPostTile(
          context, ref, theme, localizations, item as Post);
    } else {
      return _buildLikedCommentTile(
          context, ref, theme, localizations, item as Comment);
    }
  }

  Widget _buildLikedPostTile(BuildContext context, WidgetRef ref, dynamic theme,
      AppLocalizations localizations, Post post) {
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(post.authorCPId));

    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen
        context.push('/community/forum/post/${post.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.grey[100]!,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with interaction type and author info
            Row(
              children: [
                // Like indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primary[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.heart,
                    size: 14,
                    color: theme.primary[600],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  localizations.translate('liked-post'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Navigation indicator
                Icon(
                  LucideIcons.externalLink,
                  size: 16,
                  color: theme.grey[400],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Author info
            Row(
              children: [
                authorProfileAsync.when(
                  data: (authorProfile) {
                    final isAuthorAnonymous = authorProfile.isAnonymous;
                    final isAuthorPlusUser =
                        authorProfile.hasPlusSubscription();

                    return AvatarWithAnonymity(
                      isDeleted: authorProfile.isDeleted,
                      cpId: post.authorCPId,
                      isAnonymous: isAuthorAnonymous,
                      size: 24,
                      avatarUrl: authorProfile.avatarUrl,
                      isPlusUser: isAuthorPlusUser,
                    );
                  },
                  loading: () => CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 12,
                      color: theme.grey[400],
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 12,
                      color: theme.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: authorProfileAsync.when(
                    data: (authorProfile) {
                      final displayName = _getLocalizedDisplayName(
                        authorProfile.getDisplayNameWithPipeline(),
                        localizations,
                      );

                      return Text(
                        displayName,
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[600],
                          fontSize: 12,
                        ),
                      );
                    },
                    loading: () => Text(
                      localizations.translate('community-loading'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    error: (_, __) => Text(
                      localizations.translate('community-unknown-user'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(post.createdAt, localizations),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Post title
            Text(
              post.title,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Post body preview
            Text(
              post.body,
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Post stats
            Row(
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 14,
                  color: theme.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  post.likeCount.toString(),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.messageCircle,
                  size: 14,
                  color: theme.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.translate('view-post'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedCommentTile(BuildContext context, WidgetRef ref,
      dynamic theme, AppLocalizations localizations, Comment comment) {
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(comment.authorCPId));

    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen where this comment exists
        context.push('/community/forum/post/${comment.postId}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.grey[100]!,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with interaction type and author info
            Row(
              children: [
                // Like indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primary[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.heart,
                    size: 14,
                    color: theme.primary[600],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  localizations.translate('liked-comment'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Navigation indicator
                Icon(
                  LucideIcons.externalLink,
                  size: 16,
                  color: theme.grey[400],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Author info
            Row(
              children: [
                authorProfileAsync.when(
                  data: (authorProfile) {
                    final isAuthorAnonymous = authorProfile.isAnonymous;
                    final isAuthorPlusUser =
                        authorProfile.hasPlusSubscription();

                    return AvatarWithAnonymity(
                      isDeleted: authorProfile.isDeleted,
                      cpId: comment.authorCPId,
                      isAnonymous: isAuthorAnonymous,
                      size: 24,
                      avatarUrl: authorProfile.avatarUrl,
                      isPlusUser: isAuthorPlusUser,
                    );
                  },
                  loading: () => CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 12,
                      color: theme.grey[400],
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 12,
                      color: theme.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: authorProfileAsync.when(
                    data: (authorProfile) {
                      final displayName = _getLocalizedDisplayName(
                        authorProfile.getDisplayNameWithPipeline(),
                        localizations,
                      );

                      return Text(
                        displayName,
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[600],
                          fontSize: 12,
                        ),
                      );
                    },
                    loading: () => Text(
                      localizations.translate('community-loading'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    error: (_, __) => Text(
                      localizations.translate('community-unknown-user'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(comment.createdAt, localizations),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment content
            Text(
              comment.body,
              style: TextStyles.body.copyWith(
                color: theme.grey[800],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Comment stats
            Row(
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 14,
                  color: theme.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  comment.likeCount.toString(),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.messageCircle,
                  size: 14,
                  color: theme.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.translate('view-post'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return localizations.translate('just-now');
    } else if (difference.inHours < 1) {
      return localizations
          .translate('minutes-ago')
          .replaceAll('{minutes}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return localizations
          .translate('hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return localizations
          .translate('days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
