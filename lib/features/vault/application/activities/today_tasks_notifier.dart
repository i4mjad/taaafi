import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

import 'package:reboot_app_3/features/vault/application/activities/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_tasks_notifier.g.dart';

@riverpod
class TodayTasks extends _$TodayTasks {
  @override
  Map<String, OngoingActivityTask> build() {
    return {};
  }

  void updateTaskCompletion(String taskId, bool isCompleted) {
    if (state.containsKey(taskId)) {
      state = {
        ...state,
        taskId: state[taskId]!.copyWith(isCompleted: isCompleted),
      };
    }
  }

  void setTasks(List<OngoingActivityTask> tasks) {
    state = {
      for (var task in tasks) task.scheduledTaskId: task,
    };
  }

  List<OngoingActivityTask> get tasks => state.values.toList();
}

// Stream provider that updates the state notifier
@riverpod
Stream<List<OngoingActivityTask>> todayTasksStream(TodayTasksStreamRef ref) {
  final notifier = ref.watch(todayTasksProvider.notifier);

  return ref.read(activityServiceProvider).getTodayTasksStream().map((tasks) {
    notifier.setTasks(tasks);
    return tasks;
  });
}
