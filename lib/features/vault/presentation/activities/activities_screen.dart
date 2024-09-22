import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/day_task_widget.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "activities", false, true),
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

class OngoingActivitiesWidget extends StatelessWidget {
  const OngoingActivitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    var records = [
      OngoingActivity(
        "1",
        'تمرين المتابعة اليومية',
        DateTime(2022, 8, 28),
        59,
      ),
      OngoingActivity(
        "2",
        'تمرين الامتنان',
        DateTime(2024, 9, 20),
        0,
      ),
      OngoingActivity(
        "3",
        'كتابة اليوميات',
        DateTime(2022, 5, 2),
        100,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('ongoing-activities'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        verticalSpace(Spacing.points8),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return OngoingActivitiyWidget(
              index + 1,
              records[index],
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              verticalSpace(Spacing.points8),
          itemCount: records.length,
        )
      ],
    );
  }
}

class TodayTasksWidget extends StatelessWidget {
  const TodayTasksWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    var records = [
      ActivityTask(
        "1",
        'كتابة اليوميات',
        "تدوين الرحلة",
        "1",
        true,
        DateTime(2024, 5, 2),
      ),
      ActivityTask(
        "2",
        'كتابة اليوميات',
        "تدوين الرحلة",
        "12",
        false,
        DateTime(2024, 5, 2),
      ),
      ActivityTask(
        "3",
        'كتابة اليوميات',
        "تدوين الرحلة",
        "134",
        false,
        DateTime(2024, 5, 2),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context).translate('today-tasks'),
                style: TextStyles.h6.copyWith(color: theme.primary[900])),
            horizontalSpace(Spacing.points8),
            RichText(
              text: TextSpan(
                style: TextStyles.h6,
                children: [
                  TextSpan(
                    text: '2',
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
                    text: '3',
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
                  color: theme.grey[600],
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points16),
        ListView.separated(
          shrinkWrap:
              true, // This makes the ListView take up only the needed space
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return DayTaskWidget(
              records[index],
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              verticalSpace(Spacing.points8),
          itemCount: records.length,
        )
      ],
    );
  }
}

class OngoingActivitiyWidget extends ConsumerWidget {
  const OngoingActivitiyWidget(
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
    return WidgetsContainer(
      backgroundColor: theme.primary[50],
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      borderSide: BorderSide(color: theme.primary[100]!),
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
                activity.title,
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points4),
              Row(
                children: [
                  Text(
                    'تاريخ البداية: ',
                    style: TextStyles.small.copyWith(color: theme.grey[700]),
                  ),
                  Text(
                    getDisplayDate(activity.startingDate, locale!.languageCode),
                    style: TextStyles.small.copyWith(color: theme.grey[700]),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'نسبة الانجاز: ',
                    style: TextStyles.small.copyWith(color: theme.grey[700]),
                  ),
                  Text(
                    "${activity.activityProgress} %",
                    style: TextStyles.smallBold.copyWith(
                      color:
                          getPercentageColor(activity.activityProgress, theme),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          Icon(
            LucideIcons.chevronLeft,
            color: theme.grey[500],
          ),
        ],
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
