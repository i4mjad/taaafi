import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/utils/icon_mapper.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content.dart';

class ContentItem extends StatelessWidget {
  final CursorContent content;

  const ContentItem({
    required this.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 0,
          spreadRadius: 1,
          offset: Offset(
            0,
            0,
          ),
        ),
      ],
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            IconMapper.getIconFromString(content.type.iconName),
            color: theme.primary[600],
          ),
          horizontalSpace(Spacing.points8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.name,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points4),
              Text(
                '${content.type.name} • ${content.category.name} • ${content.owner.name}',
                style: TextStyles.small.copyWith(
                  color: theme.grey[700],
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(LucideIcons.link, color: theme.grey[400])
        ],
      ),
    );
  }
}
