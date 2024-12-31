import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/task_widget.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/update_ongoing_activity_sheet.dart';

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
          appBar: appBar(context, ref, details.activity.name),
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

  AppBar appBar(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    final theme = AppTheme.of(context);
    return AppBar(
      title: Text(
        title,
        style: TextStyles.screenHeadding.copyWith(
          color: theme.grey[900],
          height: 1,
        ),
      ),
      backgroundColor: theme.backgroundColor,
      surfaceTintColor: theme.backgroundColor,
      centerTitle: false,
      shadowColor: theme.grey[100],
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return OngoingActivitySettingsSheet(ongoingActivityId);
                  });
            },
            child: Icon(
              LucideIcons.settings,
              color: theme.grey[900],
            ),
          ),
        )
      ],
      leadingWidth: 16,
    );
  }
}

class OngoingActivitySettingsSheet extends ConsumerWidget {
  const OngoingActivitySettingsSheet(this.ongoingActivityId, {super.key});

  final String ongoingActivityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('activity-settings'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return UpdateOngoingActivitySheet(ongoingActivityId);
                },
              );
            },
            child: WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.warn[700]!, width: 0.5),
              // boxShadow: Shadows.mainShadows,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('new-begining'),
                  style: TextStyles.body.copyWith(color: theme.warn[700]),
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),
          GestureDetector(
            onTap: () => _showDeleteConfirmation(context, ref),
            child: WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.error[700]!, width: 0.5),
              // boxShadow: Shadows.mainShadows,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('remove-activity'),
                  style: TextStyles.body.copyWith(color: theme.error[700]),
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[900]!, width: 0.5),
              boxShadow: Shadows.mainShadows,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('close'),
                  style: TextStyles.body.copyWith(color: theme.primary[900]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref) async {
    final theme = AppTheme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('warning'),
          style: TextStyles.h6.copyWith(color: theme.error[700]),
        ),
        content: Text(
          AppLocalizations.of(context).translate('delete-activity-warning'),
          style: TextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              // First pop the dialog
              Navigator.pop(dialogContext);
              // Then pop the settings sheet
              Navigator.pop(context);

              // Delete the activity
              await ref
                  .read(
                      ongoingActivityDetailsNotifierProvider(ongoingActivityId)
                          .notifier)
                  .deleteActivity();

              // Navigate using a delayed call to ensure previous operations are complete
              if (context.mounted) {
                Future.microtask(() {
                  context.goNamed(RouteNames.activities.name);
                });
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyles.body.copyWith(color: theme.error[700]),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final groupedTasks = _groupTasksByActivityTask();
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
          itemCount: groupedTasks.length,
          separatorBuilder: (_, __) => verticalSpace(Spacing.points16),
          itemBuilder: (context, index) {
            final activityTask = groupedTasks.keys.elementAt(index);
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
            Padding(
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
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (scheduledTask.taskDatetime.isAfter(tomorrow)) {
      return Colors.grey[400]!;
    }

    final isCompleted = scheduledTask.isCompleted;
    return isCompleted ? theme.success[300]! : theme.error[300]!;
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
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(50, 50, 93, 0.25),
              blurRadius: 5,
              spreadRadius: -1,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 3,
              spreadRadius: -1,
              offset: Offset(0, 1),
            ),
          ],
          child: Text(
            details.activity.description,
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
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
                Icon(LucideIcons.calendar, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  getDisplayDate(details.startDate, locale!.languageCode),
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
