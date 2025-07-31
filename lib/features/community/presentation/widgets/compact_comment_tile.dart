import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';

class CompactCommentTile extends ConsumerWidget {
  final Comment comment;

  const CompactCommentTile({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final authorProfileAsync =
        ref.watch(communityProfileByIdProvider(comment.authorCPId));

    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen
        context.push('/community/post/${comment.postId}');
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
            // Comment header with author info
            Row(
              children: [
                // Author avatar
                authorProfileAsync.when(
                  data: (authorProfile) {
                    final isAuthorAnonymous =
                        authorProfile?.isAnonymous ?? false;
                    final isAuthorPlusUser =
                        authorProfile?.hasPlusSubscription() ?? false;

                    return AvatarWithAnonymity(
                      cpId: comment.authorCPId,
                      isAnonymous: isAuthorAnonymous,
                      size: 32,
                      avatarUrl: authorProfile?.avatarUrl,
                      isPlusUser: isAuthorPlusUser,
                    );
                  },
                  loading: () => CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 16,
                      color: theme.grey[400],
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.grey[200],
                    child: Icon(
                      LucideIcons.user,
                      size: 16,
                      color: theme.grey[400],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Author name and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      authorProfileAsync.when(
                        data: (authorProfile) {
                          final isAuthorAnonymous =
                              authorProfile?.isAnonymous ?? false;
                          final displayName = isAuthorAnonymous
                              ? localizations.translate('community-anonymous')
                              : (authorProfile?.displayName ??
                                  localizations
                                      .translate('community-unknown-user'));

                          return Text(
                            displayName,
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                        loading: () => Text(
                          localizations.translate('community-loading'),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                          ),
                        ),
                        error: (_, __) => Text(
                          localizations.translate('community-unknown-user'),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(comment.createdAt, localizations),
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation indicator
                Icon(
                  LucideIcons.externalLink,
                  size: 16,
                  color: theme.grey[400],
                ),
              ],
            ),

            const SizedBox(height: 12),

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
                  color: theme.primary[500],
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.translate('view-post'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
