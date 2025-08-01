import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/vote_button.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';

class PostCard extends ConsumerWidget {
  final String postId;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.postId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    final isPlusUser = ref.watch(hasActiveSubscriptionProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with author info
              Row(
                children: [
                  AvatarWithAnonymity(
                    cpId: 'placeholder_id',
                    isAnonymous: false,
                    isPlusUser: isPlusUser,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username', // Placeholder
                          style: TextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '2 hours ago', // Placeholder
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'General', // Placeholder category
                      style: TextStyles.caption.copyWith(
                        color: theme.primary[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Post title
              Text(
                'Sample Post Title', // Placeholder
                style: TextStyles.h6.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Post body preview
              Text(
                'This is a sample post body that shows a preview of the content...', // Placeholder
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer with vote buttons and comment count
              Row(
                children: [
                  VoteButton(
                    score: 5, // Placeholder
                    onVote: (value) {
                      // Handle vote
                    },
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: theme.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '3 comments', // Placeholder
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
