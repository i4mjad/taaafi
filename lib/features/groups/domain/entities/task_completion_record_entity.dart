/// Individual completion record for a task
class TaskCompletionRecord {
  final String taskId;
  final DateTime completedAt;
  final int pointsEarned;

  const TaskCompletionRecord({
    required this.taskId,
    required this.completedAt,
    required this.pointsEarned,
  });

  /// Check if completion was today
  bool isCompletedToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDay = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );
    return completedDay.isAtSameMomentAs(today);
  }

  /// Check if completion was this week
  bool isCompletedThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return completedAt.isAfter(startOfWeek);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'completedAt': completedAt.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }

  factory TaskCompletionRecord.fromFirestore(Map<String, dynamic> data) {
    return TaskCompletionRecord(
      taskId: data['taskId'] as String,
      completedAt: DateTime.parse(data['completedAt'] as String),
      pointsEarned: data['pointsEarned'] as int,
    );
  }
}

