import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/day_task_widget.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final locale = ref.watch(localeNotifierProvider);

    var records = [
      ActivityTask("1", 'كتابة اليوميات', "تدوين الرحلة", "1", true,
          DateTime(2024, 5, 2),""),
      ActivityTask("2", 'كتابة اليوميات', "تدوين الرحلة", "12", false,
          DateTime(2024, 5, 2),""),
      ActivityTask("3", 'كتابة اليوميات', "تدوين الرحلة", "134", false,
          DateTime(2024, 5, 2),""),
      ActivityTask("4", 'ممارسة الرياضة', "النشاط البدني", "3", true,
          DateTime(2024, 5, 3),""),
      ActivityTask(
          "5", 'قراءة كتاب', "التعلم الذاتي", "4", true, DateTime(2024, 5, 3),""),
      ActivityTask(
          "6", 'مشاهدة فيلم', "الترفيه", "5", false, DateTime(2024, 5, 4),""),
      ActivityTask("7", 'كتابة اليوميات', "تدوين الرحلة", "6", true,
          DateTime(2024, 5, 4),""),
      ActivityTask("8", 'التأمل', "الاسترخاء", "7", true, DateTime(2024, 5, 5),""),
      ActivityTask(
          "9", 'التنزه', "الاسترخاء", "8", false, DateTime(2024, 5, 5),""),
      ActivityTask("10", 'تخطيط اليوم', "التخطيط الشخصي", "9", true,
          DateTime(2024, 5, 6),""),
      ActivityTask("11", 'كتابة اليوميات', "تدوين الرحلة", "10", true,
          DateTime(2024, 5, 6),""),
      ActivityTask("12", 'مراجعة الأهداف', "التطوير الشخصي", "11", false,
          DateTime(2024, 5, 7),""),
      ActivityTask("13", 'الذهاب للجيم', "النشاط البدني", "12", true,
          DateTime(2024, 5, 7),""),
      ActivityTask("14", 'تطوير مهارة جديدة', "التعلم الذاتي", "13", false,
          DateTime(2024, 5, 8),""),
      ActivityTask(
          "15", 'التأمل', "الاسترخاء", "14", true, DateTime(2024, 5, 8),""),
      ActivityTask("16", 'قراءة مقالة', "التعلم الذاتي", "15", false,
          DateTime(2024, 5, 9),""),
      ActivityTask("17", 'مشاهدة وثائقي', "التعلم الذاتي", "16", true,
          DateTime(2024, 5, 9),""),
      ActivityTask("18", 'كتابة اليوميات', "تدوين الرحلة", "17", false,
          DateTime(2024, 5, 10),""),
      ActivityTask("19", 'الاسترخاء في الطبيعة', "الاسترخاء", "18", true,
          DateTime(2024, 5, 10),""),
      ActivityTask("20", 'التخطيط للأسبوع', "التخطيط الشخصي", "19", false,
          DateTime(2024, 5, 11),""),
      ActivityTask("21", 'ممارسة الرياضة', "النشاط البدني", "20", true,
          DateTime(2024, 5, 11),""),
      ActivityTask("22", 'مشاركة قصة', "التواصل الاجتماعي", "21", false,
          DateTime(2024, 5, 12),""),
      ActivityTask("23", 'كتابة اليوميات', "تدوين الرحلة", "22", true,
          DateTime(2024, 5, 12),""),
      ActivityTask(
          "24", 'مشاهدة فيلم', "الترفيه", "23", false, DateTime(2024, 5, 13),""),
      ActivityTask("25", 'التخطيط لرحلة', "الاسترخاء", "24", true,
          DateTime(2024, 5, 13),""),
      ActivityTask("26", 'الذهاب للجيم', "النشاط البدني", "25", false,
          DateTime(2024, 5, 14),""),
      ActivityTask("27", 'قراءة كتاب', "التعلم الذاتي", "26", true,
          DateTime(2024, 5, 14),""),
      ActivityTask("28", 'ممارسة الرياضة', "النشاط البدني", "27", false,
          DateTime(2024, 5, 15),""),
      ActivityTask("29", 'كتابة اليوميات', "تدوين الرحلة", "28", true,
          DateTime(2024, 5, 15),""),
      ActivityTask(
          "30", 'التأمل', "الاسترخاء", "29", false, DateTime(2024, 5, 16),""),
      ActivityTask("31", 'تطوير مهارة جديدة', "التعلم الذاتي", "30", true,
          DateTime(2024, 5, 16),""),
      ActivityTask("32", 'مراجعة الأهداف', "التطوير الشخصي", "31", false,
          DateTime(2024, 5, 17),""),
      ActivityTask("33", 'تخطيط اليوم', "التخطيط الشخصي", "32", true,
          DateTime(2024, 5, 17),""),
      ActivityTask("34", 'الاسترخاء في الطبيعة', "الاسترخاء", "33", false,
          DateTime(2024, 5, 18),""),
      ActivityTask("35", 'كتابة اليوميات', "تدوين الرحلة", "34", true,
          DateTime(2024, 5, 18),""),
      ActivityTask("36", 'قراءة مقالة', "التعلم الذاتي", "35", false,
          DateTime(2024, 5, 19),""),
      ActivityTask(
          "37", 'التأمل', "الاسترخاء", "36", true, DateTime(2024, 5, 19),""),
      ActivityTask("38", 'الذهاب للجيم', "النشاط البدني", "37", false,
          DateTime(2024, 5, 20),""),
      ActivityTask("39", 'تطوير مهارة جديدة', "التعلم الذاتي", "38", true,
          DateTime(2024, 5, 20),""),
      ActivityTask(
          "40", 'مشاهدة فيلم', "الترفيه", "39", false, DateTime(2024, 5, 21),""),
      ActivityTask("41", 'كتابة اليوميات', "تدوين الرحلة", "40", true,
          DateTime(2024, 5, 21),""),
      ActivityTask(
          "42", 'التنزه', "الاسترخاء", "41", false, DateTime(2024, 5, 22),""),
      ActivityTask(
          "43", 'التأمل', "الاسترخاء", "42", true, DateTime(2024, 5, 22),""),
      ActivityTask("44", 'مشاركة قصة', "التواصل الاجتماعي", "43", false,
          DateTime(2024, 5, 23),""),
      ActivityTask("45", 'التخطيط للأسبوع', "التخطيط الشخصي", "44", true,
          DateTime(2024, 5, 23),""),
      ActivityTask("46", 'كتابة اليوميات', "تدوين الرحلة", "45", false,
          DateTime(2024, 5, 24),""),
      ActivityTask("47", 'الذهاب للجيم', "النشاط البدني", "46", true,
          DateTime(2024, 5, 24),""),
      ActivityTask("48", 'التخطيط لرحلة', "الاسترخاء", "47", false,
          DateTime(2024, 5, 25),""),
      ActivityTask("49", 'قراءة كتاب', "التعلم الذاتي", "48", true,
          DateTime(2024, 5, 25),""),
      ActivityTask("50", 'كتابة اليوميات', "تدوين الرحلة", "49", false,
          DateTime(2024, 5, 26),""),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "all-tasks", false, true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GroupedListView<ActivityTask, DateTime>(
          elements: records,
          groupBy: (task) => task.taskDatetime,
          useStickyGroupSeparators: true,
          groupSeparatorBuilder: (DateTime date) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              getDisplayDate(date, locale!.languageCode),
              style: TextStyles.footnoteSelected,
            ),
          ),
          itemBuilder: (context, task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DayTaskWidget(task),
            );
          },
          order: GroupedListOrder.ASC,
        ),
      ),
    );
  }
}


// SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Container(
//             width: width,
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: NeverScrollableScrollPhysics(),
//                     itemBuilder: (BuildContext context, int index) {
//                       return TodayTaskWidget(
//                         records[index],
//                       );
//                     },
//                     separatorBuilder: (BuildContext context, int index) =>
//                         verticalSpace(Spacing.points8),
//                     itemCount: records.length,
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       )
