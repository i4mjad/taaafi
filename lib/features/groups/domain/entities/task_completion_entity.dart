/// Domain entity for task completions
///
/// Tracks when a participant completes a task
class TaskCompletionEntity {
  final String id;
  final String challengeId;
  final String taskId;
  final String cpId;
  final DateTime completedAt;
  final int pointsEarned;

  const TaskCompletionEntity({
    required this.id,
    required this.challengeId,
    required this.taskId,
    required this.cpId,
    required this.completedAt,
    required this.pointsEarned,
  });

  TaskCompletionEntity copyWith({
    String? id,
    String? challengeId,
    String? taskId,
    String? cpId,
    DateTime? completedAt,
    int? pointsEarned,
  }) {
    return TaskCompletionEntity(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      taskId: taskId ?? this.taskId,
      cpId: cpId ?? this.cpId,
      completedAt: completedAt ?? this.completedAt,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}

