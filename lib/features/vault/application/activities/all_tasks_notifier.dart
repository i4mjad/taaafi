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
    return _getAllTasks();
  }

  Future<List<OngoingActivityTask>> _getAllTasks() async {
    try {
      return await _service.getAllTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _getAllTasks());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
