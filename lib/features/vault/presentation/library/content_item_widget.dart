import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class ContentItem extends StatelessWidget {
  final String title;
  final String description;

  const ContentItem({
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      backgroundColor: theme.primary[50],
      borderSide: BorderSide(color: theme.primary[100]!),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.playCircle,
            color: theme.grey[900],
          ),
          horizontalSpace(Spacing.points8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points4),
              Text(
                description,
                style: TextStyles.small.copyWith(
                  color: theme.grey[700],
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(LucideIcons.link, color: theme.grey[500])
        ],
      ),
    );
  }
}
