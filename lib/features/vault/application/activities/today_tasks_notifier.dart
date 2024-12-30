import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'today_tasks_notifier.g.dart';

@riverpod
class TodayTasksNotifier extends _$TodayTasksNotifier {
  ActivityService get service => ref.read(activityServiceProvider);

  @override
  FutureOr<List<OngoingActivityTask>> build() async {
    return await service.getTodayTasks();
  }

  Future<void> refreshTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await service.getTodayTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateTaskLocally(String scheduledTaskId, bool isCompleted) {
    state.whenData((tasks) {
      final updatedTasks = tasks.map((task) {
        if (task.scheduledTaskId == scheduledTaskId) {
          return task.copyWith(isCompleted: isCompleted);
        }
        return task;
      }).toList();

      state = AsyncValue.data(updatedTasks);
    });
  }
}
