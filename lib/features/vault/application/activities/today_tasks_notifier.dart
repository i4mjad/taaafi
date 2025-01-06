import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'today_tasks_notifier.g.dart';

@riverpod
class TodayTasksNotifier extends _$TodayTasksNotifier {
  ActivityService get service => ref.read(activityServiceProvider);

  @override
  Stream<List<OngoingActivityTask>> build() {
    return service.getTodayTasksStream();
  }

  Future<void> completeTask(String taskId) async {
    try {
      await service.completeTask(taskId);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Stream<List<OngoingActivityTask>> tasksStream() {
    return service.getTodayTasksStream();
  }
}
