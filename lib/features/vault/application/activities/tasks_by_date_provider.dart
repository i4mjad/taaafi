import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_notifier.dart';

part 'tasks_by_date_provider.g.dart';

@riverpod
Future<List<OngoingActivityTask>> tasksByDateRange(
  TasksByDateRangeRef ref,
  DateTime startDate,
  DateTime endDate,
) async {
  return ref
      .read(activityNotifierProvider.notifier)
      .getTasksByDateRange(startDate, endDate);
}
