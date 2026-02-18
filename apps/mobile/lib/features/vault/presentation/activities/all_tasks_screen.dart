import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/all_tasks_notifier.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/day_task_widget.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final tasksState = ref.watch(allTasksNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "all-tasks", false, true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: tasksState.when(
          data: (tasks) => GroupedListView<OngoingActivityTask, DateTime>(
            elements: tasks,
            groupBy: (task) => task.taskDatetime,
            useStickyGroupSeparators: true,
            separator: Container(color: Colors.pink),
            groupSeparatorBuilder: (DateTime date) => Container(
              color: theme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getDisplayDate(date, locale!.languageCode),
                  style: TextStyles.footnoteSelected
                      .copyWith(color: theme.grey[900]),
                ),
              ),
            ),
            itemBuilder: (context, task) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: DayTaskWidget(
                  task,
                  activityId: task.activityId,
                ),
              ),
            ),
            order: GroupedListOrder.ASC,
          ),
          loading: () => const Center(child: Spinner()),
          error: (error, _) => Center(child: Text(error.toString())),
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
