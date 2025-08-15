import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

class DayTaskWidget extends ConsumerStatefulWidget {
  const DayTaskWidget(
    this.task, {
    required this.activityId,
    super.key,
  });

  final OngoingActivityTask task;
  final String activityId;

  @override
  ConsumerState<DayTaskWidget> createState() => _DayTaskWidgetState();
}

class _DayTaskWidgetState extends ConsumerState<DayTaskWidget> {
  bool _isUpdating = false;
  bool _localCompletionState = false;

  @override
  void initState() {
    super.initState();
    _localCompletionState = widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = Localizations.localeOf(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
      child: Row(
        children: [
          Text(
            getDisplayTime(widget.task.taskDatetime, locale.languageCode),
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
            ),
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.task.name,
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  widget.task.task.description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            SizedBox(
              width: 20,
              height: 20,
              child: Spinner(
                strokeWidth: 2,
                valueColor: theme.primary[600],
              ),
            )
          else
            Checkbox(
              value: _localCompletionState,
              onChanged: (bool? value) async {
                if (value == null) return;

                HapticFeedback.lightImpact();
                setState(() {
                  _isUpdating = true;
                  _localCompletionState = value;
                });

                try {
                  // Check if task is scheduled for future
                  final now = DateTime.now();
                  final endOfToday =
                      DateTime(now.year, now.month, now.day, 23, 59, 59);

                  if (widget.task.taskDatetime.isAfter(endOfToday)) {
                    if (context.mounted) {
                      HapticFeedback.heavyImpact();
                      getErrorSnackBar(
                        context,
                        "cannot-complete-future-tasks",
                      );
                      setState(() {
                        _localCompletionState = !value;
                      });
                    }
                    return;
                  }

                  await ref
                      .read(ongoingActivityDetailsNotifierProvider(
                              widget.activityId)
                          .notifier)
                      .updateTaskCompletion(widget.task.scheduledTaskId, value);
                } catch (e) {
                  if (context.mounted) {
                    getErrorSnackBar(context, e.toString());
                    setState(() {
                      _localCompletionState = !value;
                    });
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isUpdating = false;
                    });
                  }
                }
              },
              activeColor: theme.primary[600],
            ),
        ],
      ),
    );
  }
}
