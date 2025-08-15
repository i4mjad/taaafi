import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/application/activities/providers.dart';

part 'activity_details_provider.g.dart';

@riverpod
Future<Activity> activityDetails(Ref ref, String activityId) async {
  final service = ref.read(activityServiceProvider);
  return await service.getActivityById(activityId);
}
