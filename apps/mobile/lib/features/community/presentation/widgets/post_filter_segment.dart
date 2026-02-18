import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class PostFilterSegment extends ConsumerWidget {
  const PostFilterSegment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                context,
                theme,
                'Recent',
                isSelected: true,
                onTap: () {
                  // Handle recent filter
                },
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                context,
                theme,
                'Top',
                isSelected: false,
                onTap: () {
                  // Handle top filter
                },
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                context,
                theme,
                'Trending',
                isSelected: false,
                onTap: () {
                  // Handle trending filter
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    theme,
    String text, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary[500] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyles.caption.copyWith(
            color: isSelected ? Colors.white : theme.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
