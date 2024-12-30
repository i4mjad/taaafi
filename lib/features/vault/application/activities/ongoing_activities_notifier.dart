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

  Future<void> refreshActivities() async {
    state = const AsyncValue.loading();
    try {
      final activities = await service.getOngoingActivities();
      state = AsyncValue.data(activities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
