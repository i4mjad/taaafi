import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/ongoing_activity_settings_sheet.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/task_widget.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';

class OngoingActivitiyScreen extends ConsumerWidget {
  const OngoingActivitiyScreen(this.ongoingActivityId, {super.key});

  final String ongoingActivityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final activityState =
        ref.watch(ongoingActivityDetailsNotifierProvider(ongoingActivityId));

    return activityState.when(
      data: (details) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: plainAppBar(
            context,
            ref,
            details.activity.name,
            false,
            true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16, left: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return OngoingActivitySettingsSheet(
                                  ongoingActivityId);
                            });
                      },
                      child: Icon(
                        LucideIcons.settings,
                        color: theme.primary[600],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    verticalSpace(Spacing.points4),
                    OngoingActivityDescriptionAndUserStatisticsWidget(
                        details: details),
                    verticalSpace(Spacing.points16),
                    OngoingActivityTasksWidget(tasks: details.activityTasks),
                    verticalSpace(Spacing.points16),
                    OngoingActivityPerformanceWidget(
                      scheduledTasks: details.scheduledTasks,
                      performance: details.taskPerformance,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  const SettingsOption({
    required this.onTap,
    required this.text,
    required this.icon,
    required this.type,
    super.key,
  });

  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        boxShadow: Shadows.mainShadows,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: _getIconAndTextColor(type, theme)),
              horizontalSpace(Spacing.points16),
              Text(
                AppLocalizations.of(context).translate(text),
                style: TextStyles.body
                    .copyWith(color: _getIconAndTextColor(type, theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconAndTextColor(String type, CustomThemeData theme) {
    switch (type) {
      case 'error':
        return theme.error[600]!;
      case 'primary':
        return theme.primary[600]!;
      case 'warn':
        return theme.warn[600]!;
      case 'normal':
      default:
        return theme.grey[800]!;
    }
  }
}

class OngoingActivityPerformanceWidget extends StatelessWidget {
  const OngoingActivityPerformanceWidget({
    required this.scheduledTasks,
    required this.performance,
    super.key,
  });

  final List<OngoingActivityTask> scheduledTasks;
  final Map<String, List<bool>> performance;

  Map<ActivityTask, List<OngoingActivityTask>> _groupTasksByActivityTask() {
    final groupedTasks = <ActivityTask, List<OngoingActivityTask>>{};

    for (var scheduledTask in scheduledTasks) {
      final activityTask = scheduledTask.task;
      groupedTasks.putIfAbsent(activityTask, () => []);
      groupedTasks[activityTask]!.add(scheduledTask);
    }

    // Sort each group's scheduled tasks by date (earliest first)
    for (var tasks in groupedTasks.values) {
      tasks.sort((a, b) => a.taskDatetime.compareTo(b.taskDatetime));
    }

    return groupedTasks;
  }

  List<ActivityTask> _sortTasksByFrequency(List<ActivityTask> tasks) {
    tasks.sort((a, b) {
      int frequencyOrder(TaskFrequency frequency) {
        switch (frequency) {
          case TaskFrequency.daily:
            return 0;
          case TaskFrequency.weekly:
            return 1;
          case TaskFrequency.monthly:
            return 2;
        }
      }

      return frequencyOrder(a.frequency).compareTo(frequencyOrder(b.frequency));
    });

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTasks = _groupTasksByActivityTask();
    final sortedTasks = _sortTasksByFrequency(groupedTasks.keys.toList());
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('activity-performance'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points16),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sortedTasks.length,
          separatorBuilder: (_, __) => verticalSpace(Spacing.points16),
          itemBuilder: (context, index) {
            final activityTask = sortedTasks[index];
            final scheduledInstances = groupedTasks[activityTask]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityTask.name,
                  style: TextStyles.smallBold.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points8),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: ScheduledDatesRow(
                    scheduledInstances: scheduledInstances,
                    performance: performance,
                  ),
                ),
              ],
            );
          },
        )
      ],
    );
  }
}

class ScheduledDatesRow extends StatefulWidget {
  const ScheduledDatesRow({
    required this.scheduledInstances,
    required this.performance,
    super.key,
  });

  final List<OngoingActivityTask> scheduledInstances;
  final Map<String, List<bool>> performance;

  @override
  State<ScheduledDatesRow> createState() => _ScheduledDatesRowState();
}

class _ScheduledDatesRowState extends State<ScheduledDatesRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Find today's index
    final todayIndex = widget.scheduledInstances
        .indexWhere((task) => task.taskDatetime.isAtSameMomentAs(todayStart));

    if (todayIndex != -1) {
      // Approximate position (assuming each date item is about 100 pixels wide)
      final scrollPosition =
          (todayIndex * 100.0) - (MediaQuery.of(context).size.width / 2) + 50;
      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var scheduledTask in widget.scheduledInstances)
            GestureDetector(
              onTap: () => _showTaskDetailsSheet(context, scheduledTask, theme),
              child: Padding(
                padding: EdgeInsets.only(top: 1, bottom: 1, right: 4),
                child: WidgetsContainer(
                  padding: EdgeInsets.all(8),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(
                    color: _getBorderColor(
                      scheduledTask,
                      widget.performance[scheduledTask.task.id] ?? [],
                      theme,
                    ),
                    width: 0.5,
                  ),
                  child: Column(
                    children: [
                      Text(
                        scheduledTask.taskDatetime.day.toString(),
                        style: TextStyles.small.copyWith(
                          color: _getBorderColor(
                            scheduledTask,
                            widget.performance[scheduledTask.task.id] ?? [],
                            theme,
                          ),
                        ),
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        getDisplayMonth(
                          scheduledTask.taskDatetime,
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: TextStyles.small.copyWith(
                          color: _getBorderColor(
                            scheduledTask,
                            widget.performance[scheduledTask.task.id] ?? [],
                            theme,
                          ),
                        ),
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        scheduledTask.taskDatetime.year.toString(),
                        style: TextStyles.small.copyWith(
                          color: _getBorderColor(
                            scheduledTask,
                            widget.performance[scheduledTask.task.id] ?? [],
                            theme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBorderColor(
    OngoingActivityTask scheduledTask,
    List<bool> taskPerformance,
    CustomThemeData theme,
  ) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // If task is in the future, show grey
    if (scheduledTask.taskDatetime.isAfter(endOfToday)) {
      return Colors.grey[400]!;
    }

    // For past and current tasks, show success if completed, error if not completed
    return scheduledTask.isCompleted ? theme.success[300]! : theme.error[300]!;
  }

  void _showTaskDetailsSheet(BuildContext context,
      OngoingActivityTask scheduledTask, CustomThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ScheduledTaskDetailsSheet(
        scheduledTask: scheduledTask,
        theme: theme,
      ),
    );
  }
}

class ScheduledTaskDetailsSheet extends ConsumerStatefulWidget {
  final OngoingActivityTask scheduledTask;
  final CustomThemeData theme;

  const ScheduledTaskDetailsSheet({
    required this.scheduledTask,
    required this.theme,
    super.key,
  });

  @override
  ConsumerState<ScheduledTaskDetailsSheet> createState() =>
      _ScheduledTaskDetailsSheetState();
}

class _ScheduledTaskDetailsSheetState
    extends ConsumerState<ScheduledTaskDetailsSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: widget.theme.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.scheduledTask.task.name, style: TextStyles.h6),
          verticalSpace(Spacing.points8),
          Text(
            widget.scheduledTask.task.description,
            style: TextStyles.body.copyWith(
              color: widget.theme.grey[900],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points16),
          Text(
            '${AppLocalizations.of(context).translate("scheduled-for")}: ${getDisplayDate(widget.scheduledTask.taskDatetime, Localizations.localeOf(context).languageCode)}',
            style: TextStyles.small,
          ),
          verticalSpace(Spacing.points24),
          if (!widget.scheduledTask.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await ref
                              .read(ongoingActivityDetailsNotifierProvider(
                                      widget.scheduledTask.activityId)
                                  .notifier)
                              .updateTaskCompletion(
                                  widget.scheduledTask.scheduledTaskId, true);
                          Navigator.pop(context);
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 10.5,
                      cornerSmoothing: 1,
                    ),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.theme.primary[50]!),
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context)
                                .translate('processing'),
                            style: TextStyles.body
                                .copyWith(color: widget.theme.primary[50]),
                          ),
                        ],
                      )
                    : Text(
                        AppLocalizations.of(context)
                            .translate('mark-as-complete'),
                        style: TextStyles.body.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ] else ...[
            Column(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.badgeCheck,
                        color: widget.theme.success[600],
                        size: 64,
                      ),
                      verticalSpace(Spacing.points8),
                      Text(
                        AppLocalizations.of(context)
                            .translate('task-completed'),
                        style: TextStyles.body
                            .copyWith(color: widget.theme.success[600]),
                      ),
                    ],
                  ),
                ),
                verticalSpace(Spacing.points16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              await ref
                                  .read(ongoingActivityDetailsNotifierProvider(
                                          widget.scheduledTask.activityId)
                                      .notifier)
                                  .updateTaskCompletion(
                                      widget.scheduledTask.scheduledTaskId,
                                      false);
                              Navigator.pop(context);
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.warn[50],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 10.5,
                          cornerSmoothing: 1,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.theme.error[50]!),
                                ),
                              ),
                              horizontalSpace(Spacing.points8),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('processing'),
                                style: TextStyles.body
                                    .copyWith(color: widget.theme.warn[800]),
                              ),
                            ],
                          )
                        : Text(
                            AppLocalizations.of(context)
                                .translate('mark-as-incomplete'),
                            style: TextStyles.body.copyWith(
                              color: widget.theme.warn[600],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: widget.theme.grey[600]!, width: 0.5),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 10.5,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('close'),
                style:
                    TextStyles.caption.copyWith(color: widget.theme.grey[900]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OngoingActivityTasksWidget extends StatelessWidget {
  const OngoingActivityTasksWidget({
    required this.tasks,
    super.key,
  });

  final List<ActivityTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('activity-tasks'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points8),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final task = tasks[index];
            return GestureDetector(
              onTap: () => _showTaskDetails(context, task),
              child: TaskWidget(task),
            );
          },
          separatorBuilder: (_, __) => verticalSpace(Spacing.points8),
          itemCount: tasks.length,
        )
      ],
    );
  }

  void _showTaskDetails(BuildContext context, ActivityTask task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TaskDetailsModal(task: task),
    );
  }
}

class TaskDetailsModal extends StatelessWidget {
  final ActivityTask task;

  const TaskDetailsModal({required this.task, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: EdgeInsets.all(16),
      color: theme.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.name, style: TextStyles.h6),
          verticalSpace(Spacing.points8),
          Text(task.description, style: TextStyles.body),
          verticalSpace(Spacing.points8),
          Text(
            '${AppLocalizations.of(context).translate('frequency')}: ${_getFrequencyText(context, task.frequency)}',
            style: TextStyles.small,
          ),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Text(
                AppLocalizations.of(context).translate('close'),
                style: TextStyles.body.copyWith(color: theme.primary[600]),
              ),
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

class OngoingActivityDescriptionAndUserStatisticsWidget extends ConsumerWidget {
  const OngoingActivityDescriptionAndUserStatisticsWidget({
    required this.details,
    super.key,
  });

  final OngoingActivityDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          width: MediaQuery.of(context).size.width,
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
          boxShadow: Shadows.mainShadows,
          child: Text(
            details.activity.description,
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
              height: 1.4,
            ),
          ),
        ),
        verticalSpace(Spacing.points16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(LucideIcons.lineChart, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate(details.activity.difficulty.name),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.users, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  details.subscriberCount.toString(),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.calendarRange, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "${details.endDate.difference(details.startDate).inDays} ${AppLocalizations.of(context).translate('day')}",
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.loader2, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "${details.progress.toStringAsFixed(0)}%",
                  style: TextStyles.small,
                )
              ],
            ),
          ],
        )
      ],
    );
  }
}
