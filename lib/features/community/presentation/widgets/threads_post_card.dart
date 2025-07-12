import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';

class ThreadsPostCard extends ConsumerWidget {
  final String postId;
  final VoidCallback? onTap;

  const ThreadsPostCard({
    super.key,
    required this.postId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Header with user info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                const AvatarWithAnonymity(
                  cpId: 'user_id',
                  isAnonymous: false,
                  size: 32,
                ),
                const SizedBox(width: 12),

                // User info and content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and time
                      Row(
                        children: [
                          Text(
                            'username_example', // Placeholder
                            style: TextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.grey[900],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations
                                .translate('time-hour-ago')
                                .replaceAll('{count}', '2'),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.more_horiz,
                            color: theme.grey[400],
                            size: 16,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Post content
                      Text(
                        'This is a sample post content that would appear in the community forum. It shows how posts look similar to Threads app with clean typography and good spacing.',
                        style: TextStyles.body.copyWith(
                          color: theme.grey[900],
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Engagement buttons (Threads-style)
                      Row(
                        children: [
                          // Like button
                          _buildEngagementButton(
                            icon: LucideIcons.heart,
                            onTap: () {
                              // Handle like
                            },
                          ),
                          horizontalSpace(Spacing.points8),

                          // Comment button
                          _buildEngagementButton(
                            icon: LucideIcons.messageCircle,
                            onTap: () {
                              // Handle comment
                            },
                          ),

                          // Repost button
                          // _buildEngagementButton(
                          //   icon: LucideIcons.repeat,
                          //   onTap: () {
                          //     // Handle repost
                          //   },
                          // ),
                          // const SizedBox(width: 20),

                          // // Share button
                          // _buildEngagementButton(
                          //   icon: Icons.send_outlined,
                          //   onTap: () {
                          //     // Handle share
                          //   },
                          // ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Engagement stats
                      Text(
                        '12 ${localizations.translate('community-likes')} • 3 ${localizations.translate('community-comments')}',
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
