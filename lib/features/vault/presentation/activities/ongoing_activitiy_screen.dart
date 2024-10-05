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

class OngoingActivitiyScreen extends ConsumerWidget {
  const OngoingActivitiyScreen(this.ongoingActivitiyId, {super.key});

  final String ongoingActivitiyId;

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
          "هذا توصيف للمهمة التي تم اختيارها في الصفحة السابقة، يتم عرض توضيح للفائدة المرجوة من هذه المهمة هنا في هذا النص. كما سيتم إضافة بعض الروابط عن المهمة إن تطلب ذلك"),
      ActivityTask("2", 'كتابة اليوميات', "تدوين الرحلة", "12", false,
          DateTime(2024, 5, 2), ""),
      ActivityTask("3", 'كتابة اليوميات', "تدوين الرحلة", "134", false,
          DateTime(2024, 5, 2), ""),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, ongoingActivitiyId),
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
                  OngoingActivityDescriptionAndUserStatisticsWidget(),
                  verticalSpace(Spacing.points16),
                  OngoingActivityTasksWidget(),
                  verticalSpace(Spacing.points16),
                  OngoingActivityPerformanceWidget()
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
                    return OngoingActivitySettingsSheet(ongoingActivitiyId);
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
    super.key,
  });

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OngoingActivityDayPerformanceWidget(true),
            OngoingActivityDayPerformanceWidget(true),
            OngoingActivityDayPerformanceWidget(false),
            OngoingActivityDayPerformanceWidget(true),
            OngoingActivityDayPerformanceWidget(false),
            OngoingActivityDayPerformanceWidget(false),
            OngoingActivityDayPerformanceWidget(true),
          ],
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          "هذا توصيف للمهمة التي تم اختيارها في الصفحة السابقة، يتم عرض توضيح للفائدة المرجوة من هذه المهمة هنا في هذا النص. كما سيتم إضافة بعض الروابط عن المهمة إن تطلب ذلك"),
      ActivityTask("2", 'كتابة اليوميات', "تدوين الرحلة", "12", false,
          DateTime(2024, 5, 2), ""),
      ActivityTask("3", 'كتابة اليوميات', "تدوين الرحلة", "134", false,
          DateTime(2024, 5, 2), ""),
    ];

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
            return TaskWidget(
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

class OngoingActivityDescriptionAndUserStatisticsWidget extends ConsumerWidget {
  const OngoingActivityDescriptionAndUserStatisticsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final locale = ref.watch(localeNotifierProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        WidgetsContainer(
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
                Icon(LucideIcons.lineChart, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context).translate('easy'),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.calendar, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  getDisplayDate(DateTime.now(), locale!.languageCode),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              //TODO: this will represent the best period to do this activity
              children: [
                Icon(LucideIcons.calendarRange, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "3 " + AppLocalizations.of(context).translate('month'),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.loader2, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "29%",
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
