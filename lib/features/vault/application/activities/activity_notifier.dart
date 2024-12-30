import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'activity_notifier.g.dart';

@riverpod
class ActivityNotifier extends _$ActivityNotifier {
  ActivityService get service => ref.read(activityServiceProvider);

  @override
  FutureOr<List<Activity>> build() async {
    return _getAvailableActivities();
  }

  /// Fetches available activities
  Future<List<Activity>> _getAvailableActivities() async {
    return await service.getAvailableActivities();
  }

  /// Subscribes to activity
  Future<void> subscribeToActivity(
      String activityId, DateTime startDate, DateTime endDate) async {
    state = const AsyncValue.loading();
    try {
      await service.subscribeToActivity(startDate, endDate, activityId);
      state = AsyncValue.data(await _getAvailableActivities());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Checks if user is subscribed to an activity
  Future<bool> checkSubscription(String activityId) async {
    try {
      return await service.isUserSubscribed(activityId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
