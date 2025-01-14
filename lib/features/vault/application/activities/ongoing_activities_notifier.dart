import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'ongoing_activities_notifier.g.dart';

@riverpod
class OngoingActivitiesNotifier extends _$OngoingActivitiesNotifier {
  ActivityService get service => ref.read(activityServiceProvider);

  @override
  FutureOr<List<OngoingActivity>> build() async {
    return await service.getOngoingActivities();
  }

  Stream<List<OngoingActivity>> activitiesStream() {
    return service.getOngoingActivitiesStream();
  }

  Future<void> deleteAllActivities() async {
    try {
      await service.deleteAllOngoingActivities();
    } catch (e) {
      throw Exception('Failed to delete all activities: $e');
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await service.deleteActivity(activityId);
      state = const AsyncValue.loading();
      state = AsyncValue.data(await service.getOngoingActivities());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
