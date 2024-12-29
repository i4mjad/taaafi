import 'package:reboot_app_3/features/vault/application/activities/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';

part 'ongoing_activity_details_provider.g.dart';

@riverpod
class OngoingActivityDetailsNotifier extends _$OngoingActivityDetailsNotifier {
  late final ActivityService _service;

  @override
  FutureOr<OngoingActivityDetails> build(String activityId) async {
    // Inject the service using ref.read
    _service = ref.read(activityServiceProvider);

    // Fetch initial data
    return _getOngoingActivityDetails(activityId);
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

  /// Refreshes the activity details
  Future<void> refresh() async {
    // Set state to loading
    state = const AsyncValue.loading();
    try {
      // Update state with new data
      state = AsyncValue.data(await build(activityId));
    } catch (e, st) {
      // Set state to error with proper error handling
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates task completion status
  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateTaskCompletion(activityId, taskId, isCompleted);
      state = AsyncValue.data(await _getOngoingActivityDetails(activityId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
