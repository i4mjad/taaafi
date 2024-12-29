import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'today_tasks_notifier.g.dart';

@riverpod
class TodayTasksNotifier extends _$TodayTasksNotifier {
  late final ActivityService _service;

  @override
  FutureOr<List<OngoingActivityTask>> build() async {
    _service = ref.read(activityServiceProvider);
    return _getTodayTasks();
  }

  Future<List<OngoingActivityTask>> _getTodayTasks() async {
    return await _service.getTodayTasks();
  }

  Future<void> completeTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _service.completeTask(taskId);
      state = AsyncValue.data(await _getTodayTasks());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
