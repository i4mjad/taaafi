import 'package:reboot_app_3/features/vault/application/activities/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';

part 'all_tasks_notifier.g.dart';

@riverpod
class AllTasksNotifier extends _$AllTasksNotifier {
  late final ActivityService _service;

  @override
  FutureOr<List<OngoingActivityTask>> build() async {
    _service = ref.read(activityServiceProvider);
    return await _service.getAllTasks();
  }

  Future<void> refreshTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _service.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
