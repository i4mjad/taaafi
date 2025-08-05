import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';

class PostContentWidget extends ConsumerWidget {
  final Post post;
  final bool isPreview;
  final int? maxLines;

  const PostContentWidget({
    super.key,
    required this.post,
    this.isPreview = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post title
        if (post.title.isNotEmpty) ...[
          Text(
            post.title,
            style: TextStyles.h6.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.grey[900],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Post body
        if (post.body.isNotEmpty) ...[
          Text(
            post.body,
            style: TextStyles.body.copyWith(
              color: theme.grey[900],
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ],
      ],
    );
  }
}
