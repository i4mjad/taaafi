import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

class OngoingActivity {
  final String id;
  final String activityId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final Activity? activity;
  final List<OngoingActivityTask> scheduledTasks;
  final double progress;

  OngoingActivity({
    required this.id,
    required this.activityId,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.scheduledTasks = const [],
    this.activity,
    this.progress = 0,
  });

  factory OngoingActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OngoingActivity(
      id: doc.id,
      activityId: data['activityId'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class TaskCompletion {
  final String taskId;
  final List<DateTime> completedDates;

  TaskCompletion({
    required this.taskId,
    required this.completedDates,
  });

  factory TaskCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCompletion(
      taskId: data['taskId'] as String,
      completedDates: (data['completedDates'] as List)
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList(),
    );
  }
}
