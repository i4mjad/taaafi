import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
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
          appBar: appBar(context, ref, details.activity.name),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    OngoingActivityDescriptionAndUserStatisticsWidget(
                        details: details),
                    verticalSpace(Spacing.points16),
                    OngoingActivityTasksWidget(tasks: details.tasks),
                    verticalSpace(Spacing.points16),
                    OngoingActivityPerformanceWidget(
                      tasks: details.tasks,
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
  const OngoingActivitySettingsSheet(this.ongoingActivitiyId, {super.key});

  final String ongoingActivitiyId;
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
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          WidgetsContainer(
            backgroundColor: theme.warn[100],
            borderSide: BorderSide(color: theme.warn[600]!, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 24,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  6,
                ),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 0,
                spreadRadius: 1,
                offset: Offset(
                  0,
                  0,
                ),
              ),
            ],
            child: Center(
              child: Text(
                AppLocalizations.of(context).translate('new-begining'),
                style: TextStyles.body.copyWith(color: theme.warn[800]),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),
          WidgetsContainer(
            backgroundColor: theme.error[50],
            borderSide: BorderSide(color: theme.error[100]!),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 24,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  6,
                ),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 0,
                spreadRadius: 1,
                offset: Offset(
                  0,
                  0,
                ),
              ),
            ],
            child: Center(
              child: Text(
                AppLocalizations.of(context).translate('remove-activity'),
                style: TextStyles.body.copyWith(color: theme.error[700]),
              ),
            ),
          ),
          verticalSpace(Spacing.points32),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[50],
              borderSide: BorderSide(color: theme.primary[100]!),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(
                    0,
                    6,
                  ),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 0,
                  spreadRadius: 1,
                  offset: Offset(
                    0,
                    0,
                  ),
                ),
              ],
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
}

class OngoingActivityPerformanceWidget extends StatelessWidget {
  const OngoingActivityPerformanceWidget({
    required this.tasks,
    required this.performance,
    super.key,
  });

  final List<ActivityTask> tasks;
  final Map<String, List<bool>> performance;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('activity-performance'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        verticalSpace(Spacing.points8),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => verticalSpace(Spacing.points8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            final taskPerformance = performance[task.id] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name, style: TextStyles.small),
                verticalSpace(Spacing.points4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var isCompleted in taskPerformance)
                      OngoingActivityDayPerformanceWidget(isCompleted),
                  ],
                ),
              ],
            );
          },
        )
      ],
    );
  }
}

class OngoingActivityDayPerformanceWidget extends StatelessWidget {
  const OngoingActivityDayPerformanceWidget(
    this.isFinished, {
    super.key,
  });

  final bool isFinished;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
        padding: EdgeInsets.all(6),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(
            color: isFinished ? theme.success[300]! : theme.error[300]!,
            width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(50, 50, 93, 0.25),
            blurRadius: 5,
            spreadRadius: -1,
            offset: Offset(
              0,
              2,
            ),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 3,
            spreadRadius: -1,
            offset: Offset(
              0,
              1,
            ),
          ),
        ],
        child: Column(
          children: [
            Text(
              "28",
              style: TextStyles.smallBold.copyWith(
                color: theme.grey[900],
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              "أغسطس",
              style: TextStyles.tinyBold.copyWith(
                color: theme.grey[900],
              ),
            ),
          ],
        ));
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
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
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
            return TaskWidget(tasks[index]);
          },
          separatorBuilder: (BuildContext context, int index) =>
              verticalSpace(Spacing.points8),
          itemCount: tasks.length,
        )
      ],
    );
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
