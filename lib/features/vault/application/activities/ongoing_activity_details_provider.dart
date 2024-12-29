import 'package:reboot_app_3/features/vault/application/activities/all_tasks_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';
import 'package:reboot_app_3/features/vault/application/activities/today_tasks_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';

part 'ongoing_activity_details_provider.g.dart';

@riverpod
class OngoingActivityDetailsNotifier extends _$OngoingActivityDetailsNotifier {
  late final ActivityService _service;

  @override
  FutureOr<OngoingActivityDetails> build(String activityId) async {
    _service = ref.read(activityServiceProvider);
    return await _getOngoingActivityDetails(activityId);
  }

  /// Fetches ongoing activity details including performance data
  Future<OngoingActivityDetails> _getOngoingActivityDetails(
      String activityId) async {
    try {
      return await _service.getOngoingActivityDetails(activityId);
    } catch (e, st) {
      // Set state to error with proper error handling
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates task completion status
  Future<void> updateTaskCompletion(
      String scheduledTaskId, bool isCompleted) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateTaskCompletion(
          activityId, scheduledTaskId, isCompleted);

      // Update state with fresh data
      final updatedDetails =
          await _service.getOngoingActivityDetails(activityId);
      state = AsyncValue.data(updatedDetails);

      // Notify other providers to refresh their data
      await ref.read(todayTasksNotifierProvider.notifier).refreshTasks();
      await ref.read(allTasksNotifierProvider.notifier).refreshTasks();
      await ref
          .read(ongoingActivitiesNotifierProvider.notifier)
          .refreshActivities();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
