import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activity_overview_screen.dart';

class TaskWidget extends ConsumerWidget {
  const TaskWidget(this.task, {super.key});

  final ActivityTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name,
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points4),
              Text(
                AppLocalizations.of(context)
                    .translate('${task.frequency.name}'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[700],
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return TaskDescriptionSheet(task);
                },
              );
            },
            child: Icon(
              LucideIcons.info,
              color: theme.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(BuildContext context, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return AppLocalizations.of(context).translate('daily');
      case TaskFrequency.weekly:
        return AppLocalizations.of(context).translate('weekly');
      case TaskFrequency.monthly:
        return AppLocalizations.of(context).translate('monthly');
    }
  }
}
