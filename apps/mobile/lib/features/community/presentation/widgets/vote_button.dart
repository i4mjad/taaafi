import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class VoteButton extends ConsumerWidget {
  final int score;
  final Function(int) onVote;

  const VoteButton({
    super.key,
    required this.score,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onVote(1),
            child: Icon(
              LucideIcons.chevronUp,
              size: 20,
              color: theme.primary[600],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            score.toString(),
            style: TextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onVote(-1),
            child: Icon(
              LucideIcons.chevronDown,
              size: 20,
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
