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
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
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
      appBar: appBar(context, ref, "activities"),
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

  AppBar appBar(
    BuildContext context,
    WidgetRef ref,
    String? titleTranslationKey,
  ) {
    final theme = AppTheme.of(context);
    return AppBar(
      title: Text(
        titleTranslationKey != null
            ? AppLocalizations.of(context).translate(titleTranslationKey)
            : '',
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
              context.goNamed(RouteNames.addActivity.name);
            },
            child: Icon(
              LucideIcons.plus,
              color: theme.grey[900],
            ),
          ),
        )
      ],
      leadingWidth: 16,
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
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
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
    return StreamBuilder<List<OngoingActivityTask>>(
      stream: ref.watch(todayTasksNotifierProvider.notifier).tasksStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
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
                          color: theme.tint[800],
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
                      color: theme.grey[500],
                    ),
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points16),
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
                verticalSpace(Spacing.points4),
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
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('activity-progress'),
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                    ),
                    Text(
                      "${activity.progress.toInt()} %",
                      style: TextStyles.smallBold.copyWith(
                        color: getPercentageColor(
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
