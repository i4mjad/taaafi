import 'package:reboot_app_3/features/vault/application/activities/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';

part 'all_tasks_notifier.g.dart';

@riverpod
class AllTasksNotifier extends _$AllTasksNotifier {
  ActivityService get service => ref.read(activityServiceProvider);

  @override
  FutureOr<List<OngoingActivityTask>> build() async {
    return await service.getAllTasks();
  }

  Future<void> refreshTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await service.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
