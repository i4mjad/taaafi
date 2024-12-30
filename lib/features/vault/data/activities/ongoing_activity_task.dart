import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';

class OngoingActivityTask {
  final ActivityTask task;
  final DateTime taskDatetime;
  final bool isCompleted;
  final String scheduledTaskId;
  final String activityId;

  OngoingActivityTask({
    required this.task,
    required this.taskDatetime,
    required this.isCompleted,
    required this.scheduledTaskId,
    required this.activityId,
  });

  factory OngoingActivityTask.fromFirestore(
    DocumentSnapshot scheduledTaskDoc,
    ActivityTask baseTask,
  ) {
    final data = scheduledTaskDoc.data() as Map<String, dynamic>;
    return OngoingActivityTask(
      task: baseTask,
      taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      scheduledTaskId: scheduledTaskDoc.id,
      activityId: scheduledTaskDoc.reference.parent.parent!.id,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'taskId': task.id,
        'scheduledDate': Timestamp.fromDate(taskDatetime),
        'isCompleted': isCompleted,
        'completedAt': null,
      };

  OngoingActivityTask copyWith({
    ActivityTask? task,
    DateTime? taskDatetime,
    bool? isCompleted,
    String? scheduledTaskId,
    String? activityId,
  }) {
    return OngoingActivityTask(
      task: task ?? this.task,
      taskDatetime: taskDatetime ?? this.taskDatetime,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledTaskId: scheduledTaskId ?? this.scheduledTaskId,
      activityId: activityId ?? this.activityId,
    );
  }
}
