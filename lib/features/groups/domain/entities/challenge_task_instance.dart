import 'challenge_task_entity.dart';

/// UI-only entity for displaying task instances by date
/// Not stored in database - generated on-demand
class ChallengeTaskInstance {
  final ChallengeTaskEntity task;
  final DateTime scheduledDate;
  final TaskInstanceStatus status;
  final DateTime? completedAt;

  const ChallengeTaskInstance({
    required this.task,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
  });

  /// Check if this instance is for today
  bool isToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return scheduled.isAtSameMomentAs(today);
  }

  /// Check if this instance is in the past
  bool isPast() {
    final now = DateTime.now();
    return scheduledDate.isBefore(now);
  }
}

/// Status of a task instance
enum TaskInstanceStatus {
  completed, // ✅ Completed
  missed, // ❌ Past and not completed
  upcoming, // ⏰ Future, not yet due
  today, // 🔵 Today, not yet completed
}

