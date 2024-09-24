import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';

class ActivityOverviewScreen extends ConsumerWidget {
  const ActivityOverviewScreen(this.activityId, {super.key});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, activityId, false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ActivityOverviewWidget(),
                verticalSpace(Spacing.points16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('activity-tasks'),
                      style: TextStyles.h6,
                    ),
                    verticalSpace(Spacing.points8),
                    SizedBox(
                      height: height * 0.336, // Set the desired height
                      child: ListView.separated(
                        itemBuilder: (BuildContext context, int index) {
                          return DayTaskWidget(
                            records[index],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            verticalSpace(Spacing.points8),
                        itemCount: records.length,
                      ),
                    )
                  ],
                ),
                Spacer(),
                WidgetsContainer(
                  backgroundColor: theme.primary[900],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate("add-the-activity"),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[50],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityOverviewWidget extends ConsumerWidget {
  const ActivityOverviewWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        WidgetsContainer(
          backgroundColor: theme.primary[50],
          borderSide: BorderSide(color: theme.primary[100]!),
          width: width,
          child: Text(
            'هذا توصيف للقائمة والفكرة منها وطبيعة المحتوى الموجود في هذه القائمة. مثال: قائمة كيف أبدأ تحتوي على بعض المصادر لمساعدة المتعافي للبدء في التعافي وكيف يدخل لهذا العالم. سيتم إضافة التوصيف عند إضافة القائمة.',
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
                Icon(LucideIcons.lineChart, color: theme.primary[900]),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context).translate('easy'),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.users, color: theme.primary[900]),
                verticalSpace(Spacing.points4),
                Text(
                  "2808 " +
                      AppLocalizations.of(context).translate('subscriber'),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              //TODO: this will represent the best period to do this activity
              children: [
                Icon(LucideIcons.calendarRange, color: theme.primary[900]),
                verticalSpace(Spacing.points4),
                Text(
                  "3 " + AppLocalizations.of(context).translate('month'),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.panelLeftInactive, color: theme.primary[900]),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context).translate('all-levels'),
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

class DayTaskWidget extends ConsumerWidget {
  const DayTaskWidget(this.dailyRecord, {super.key});
  final ActivityTask dailyRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return WidgetsContainer(
      padding: EdgeInsets.all(16),
      backgroundColor: theme.primary[50],
      borderSide: BorderSide(color: theme.primary[100]!),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dailyRecord.id,
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dailyRecord.taskName,
                style: TextStyles.body.copyWith(color: theme.grey[900]),
              ),
              // verticalSpace(Spacing.points4),
            ],
          ),
          Spacer(),
          Icon(LucideIcons.info, color: theme.primary[900])
        ],
      ),
    );
  }
}
