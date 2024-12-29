import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/all_tasks_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/application/activities/today_tasks_notifier.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

class DayTaskWidget extends ConsumerWidget {
  const DayTaskWidget(
    this.task, {
    required this.activityId,
    super.key,
  });

  final OngoingActivityTask task;
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.task.name,
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  task.task.description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) async {
              try {
                // Check if task is scheduled for future
                final today = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                );

                if (task.taskDatetime.isAfter(today)) {
                  if (context.mounted) {
                    getErrorSnackBar(context, "cannot-complete-future-tasks");
                  }
                  return;
                }

                await ref
                    .read(ongoingActivityDetailsNotifierProvider(activityId)
                        .notifier)
                    .updateTaskCompletion(task.scheduledTaskId, value ?? false);

                // Refresh all providers that show tasks
                ref.invalidate(todayTasksNotifierProvider);
                ref.invalidate(allTasksNotifierProvider);
                ref.invalidate(
                    ongoingActivitiesNotifierProvider); // For progress updates
              } catch (e) {
                if (context.mounted) {
                  getErrorSnackBar(context, e.toString());
                }
              }
            },
            activeColor: theme.primary[600],
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
