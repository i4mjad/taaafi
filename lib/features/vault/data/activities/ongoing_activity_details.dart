import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';

class OngoingActivityDetails {
  final Activity activity;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final List<ActivityTask> tasks;
  final Map<String, List<bool>> taskPerformance;

  OngoingActivityDetails({
    required this.activity,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.tasks,
    required this.taskPerformance,
  });
}
