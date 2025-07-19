import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/day_task_widget.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/today_tasks_notifier.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "activities", false, true, actions: [
        IconButton(
          onPressed: () {
            context.goNamed(RouteNames.addActivity.name);
          },
          icon: Icon(LucideIcons.plus),
        )
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TodayTasksWidget(),
                  verticalSpace(Spacing.points16),
                  OngoingActivitiesWidget()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OngoingActivitiesWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return StreamBuilder<List<OngoingActivity>>(
      stream: ref
          .watch(ongoingActivitiesNotifierProvider.notifier)
          .activitiesStream(),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('ongoing-activities'),
              style: TextStyles.h6.copyWith(color: theme.grey[900]),
            ),
            verticalSpace(Spacing.points8),
            if (snapshot.hasError)
              Center(child: Text(snapshot.error.toString()))
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Spinner())
            else if (snapshot.data!.isEmpty)
              Column(
                children: [
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context)
                        .translate('no-ongoing-activities'),
                    style: TextStyles.body.copyWith(color: theme.grey[500]),
                  ),
                  verticalSpace(Spacing.points8),
                  GestureDetector(
                    onTap: () {
                      context.goNamed(RouteNames.addActivity.name);
                    },
                    child: WidgetsContainer(
                      width: MediaQuery.of(context).size.width - 32,
                      boxShadow: Shadows.mainShadows,
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(
                        color: theme.grey[600]!,
                        width: 0.5,
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('add-activity'),
                          style: TextStyles.caption
                              .copyWith(color: theme.primary[600]),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => verticalSpace(Spacing.points8),
                itemBuilder: (context, index) => OngoingActivityWidget(
                  index + 1,
                  snapshot.data![index],
                ),
              ),
          ],
        );
      },
    );
  }
}

class TodayTasksWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final tasksAsync = ref.watch(todayTasksStreamProvider);

    return tasksAsync.when(
      data: (tasks) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).translate('today-tasks'),
                  style: TextStyles.h6.copyWith(color: theme.primary[900]),
                ),
                horizontalSpace(Spacing.points8),
                RichText(
                  text: TextSpan(
                    style: TextStyles.h6,
                    children: [
                      TextSpan(
                        text: tasks
                            .where((task) => task.isCompleted)
                            .length
                            .toString(),
                        style: TextStyle(
                          color: theme.success[600],
                        ),
                      ),
                      TextSpan(
                        text: '/',
                        style: TextStyle(
                          color: theme.grey[600],
                        ),
                      ),
                      TextSpan(
                        text: tasks.length.toString(),
                        style: TextStyle(
                          color: theme.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames.allTasks.name);
                  },
                  child: Text(
                    AppLocalizations.of(context).translate('show-all'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points16),
            if (tasks.isEmpty)
              Container(
                height: 100,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('no-tasks-today'),
                    style:
                        TextStyles.bodyLarge.copyWith(color: theme.grey[500]),
                  ),
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => verticalSpace(Spacing.points8),
              itemBuilder: (context, index) => DayTaskWidget(
                tasks[index],
                activityId: tasks[index].activityId,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Spinner()),
      error: (error, stack) => Center(
        child: Text(
          error.toString(),
          style: TextStyles.body.copyWith(color: theme.error[600]),
        ),
      ),
    );
  }
}

class OngoingActivityWidget extends ConsumerWidget {
  const OngoingActivityWidget(
    this.order,
    this.activity, {
    super.key,
  });

  final int order;
  final OngoingActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.ongoingActivity.name,
            pathParameters: {"id": activity.id});
      },
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        boxShadow: Shadows.mainShadows,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              order.toString(),
              style: TextStyles.h6.copyWith(color: theme.grey[900]),
            ),
            horizontalSpace(Spacing.points16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activity?.name ?? '',
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points8),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('ongoing-activity-starting-date'),
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                    ),
                    Text(
                      getDisplayDate(activity.startDate, locale!.languageCode),
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points8),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('activity-progress'),
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                    ),
                    Text(
                      activity.startDate.isAfter(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          23,
                          59,
                          59,
                        ),
                      )
                          ? AppLocalizations.of(context)
                              .translate('not-started')
                          : "${activity.progress.toInt()} %",
                      style: TextStyles.smallBold.copyWith(
                        color: activity.startDate.isAfter(
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            23,
                            59,
                            59,
                          ),
                        )
                            ? theme.grey[700]
                            : getPercentageColor(
                                activity.progress.toInt(), theme),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Icon(
              locale.languageCode == 'en'
                  ? LucideIcons.chevronRight
                  : LucideIcons.chevronLeft,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Color getPercentageColor(int percentage, CustomThemeData theme) {
    if (percentage <= 33) {
      return theme.error[700]!;
    } else if (percentage <= 66) {
      return theme.warn[700]!;
    } else {
      return theme.success[700]!;
    }
  }
}
