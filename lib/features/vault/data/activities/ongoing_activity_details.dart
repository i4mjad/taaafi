import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

class OngoingActivityDetails {
  final Activity activity;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final List<ActivityTask> activityTasks;
  final List<OngoingActivityTask> scheduledTasks;
  final Map<String, List<bool>> taskPerformance;
  final int subscriberCount;

  OngoingActivityDetails({
    required this.activity,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.activityTasks,
    required this.scheduledTasks,
    required this.taskPerformance,
    required this.subscriberCount,
  });

  OngoingActivityDetails copyWith({
    Activity? activity,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    List<ActivityTask>? activityTasks,
    List<OngoingActivityTask>? scheduledTasks,
    Map<String, List<bool>>? taskPerformance,
    int? subscriberCount,
  }) {
    return OngoingActivityDetails(
      activity: activity ?? this.activity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      activityTasks: activityTasks ?? this.activityTasks,
      scheduledTasks: scheduledTasks ?? this.scheduledTasks,
      taskPerformance: taskPerformance ?? this.taskPerformance,
      subscriberCount: subscriberCount ?? this.subscriberCount,
    );
  }
}
