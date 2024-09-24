import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
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
          "هذا توصيف للمهمة التي تم اختيارها في الصفحة السابقة، يتم عرض توضيح للفائدة المرجوة من هذه المهمة هنا في هذا النص. كما سيتم إضافة بعض الروابط عن المهمة إن تطلب ذلك"),
      ActivityTask("2", 'كتابة اليوميات', "تدوين الرحلة", "12", false,
          DateTime(2024, 5, 2), ""),
      ActivityTask("3", 'كتابة اليوميات', "تدوين الرحلة", "134", false,
          DateTime(2024, 5, 2), ""),
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
                ActivityDescriptionAndStatisticsWidget(),
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
                      height: height * 0.336,
                      child: ListView.separated(
                        itemBuilder: (BuildContext context, int index) {
                          return TaskWidget(
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
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return AddTheActivitySheet(activityId);
                        });
                  },
                  child: WidgetsContainer(
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

class ActivityDescriptionAndStatisticsWidget extends ConsumerWidget {
  const ActivityDescriptionAndStatisticsWidget({
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

class TaskWidget extends ConsumerWidget {
  const TaskWidget(this.task, {super.key});
  final ActivityTask task;

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
            task.id,
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.taskName,
                style: TextStyles.body.copyWith(color: theme.grey[900]),
              ),
              // verticalSpace(Spacing.points4),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return TaskDescriptionSheet(task);
                  });
            },
            child: Icon(LucideIcons.info, color: theme.primary[900]),
          )
        ],
      ),
    );
  }
}

class TaskDescriptionSheet extends ConsumerWidget {
  const TaskDescriptionSheet(this.task, {super.key});

  final ActivityTask task;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.taskName,
                  style: TextStyles.h6.copyWith(color: theme.grey[900])),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(LucideIcons.xCircle, color: theme.grey[900]),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          Text(task.description,
              style: TextStyles.body.copyWith(color: theme.grey[900])),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.secondary[100],
              borderSide: BorderSide(color: theme.secondary[200]!),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate("close"),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AddTheActivitySheet extends ConsumerStatefulWidget {
  const AddTheActivitySheet(this.activityId, {super.key});

  final String activityId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddTheActivitySheetState();
}

class _AddTheActivitySheetState extends ConsumerState<AddTheActivitySheet> {
  final activityStartingDateController = TextEditingController();
  late DateTime activityStartingDateTime = DateTime.now();

  final activityEndingDateController = TextEditingController();
  late DateTime activityEndingDateTime = DateTime.now();

  Future<void> _selectActivityStartingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        var pickedStarting = DisplayDateTime(pickedDateTime, language);
        setState(() {
          activityStartingDateController.text = pickedStarting.displayDateTime;
          activityStartingDateTime = pickedStarting.date;
        });
      }
    }
  }

  Future<void> _selectActivityEndingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        var pickedEnding = DisplayDateTime(pickedDateTime, language);
        setState(() {
          activityEndingDateController.text = pickedEnding.displayDateTime;
          activityEndingDateTime = pickedEnding.date;
        });
      }
    }
  }

  @override
  void dispose() {
    activityStartingDateController.dispose();
    activityEndingDateController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).translate('activity-period'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900])),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(LucideIcons.xCircle, color: theme.grey[900]),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          // ADD HERE
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[900],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate("close"),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[50],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
    ;
  }
}
