import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'ongoing_activities_notifier.g.dart';

@riverpod
class OngoingActivitiesNotifier extends _$OngoingActivitiesNotifier {
  late final ActivityService _service;

  @override
  FutureOr<List<OngoingActivity>> build() async {
    _service = ref.read(activityServiceProvider);
    return await _getOngoingActivities();
  }

  Future<List<OngoingActivity>> _getOngoingActivities() async {
    return await _service.getOngoingActivities();
  }
}
