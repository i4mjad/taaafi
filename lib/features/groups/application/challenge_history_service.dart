import '../domain/entities/challenge_entity.dart';
import '../domain/entities/challenge_participation_entity.dart';
import '../domain/entities/challenge_task_entity.dart';
import '../domain/entities/challenge_task_instance.dart';
import '../domain/entities/task_completion_record_entity.dart';

/// Service to generate task instances for history view
class ChallengeHistoryService {
  /// Generate task instances from joinedAt to challenge endDate
  List<ChallengeTaskInstance> generateTaskInstances({
    required ChallengeEntity challenge,
    required ChallengeParticipationEntity participation,
  }) {
    final instances = <ChallengeTaskInstance>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(
      challenge.endDate.year,
      challenge.endDate.month,
      challenge.endDate.day,
    );

    for (final task in challenge.tasks) {
      final taskDates = _generateDatesForTask(
        task.frequency,
        participation.joinedAt,
        endDate, // Changed from 'today' to 'endDate'
      );

      for (final date in taskDates) {
        final completion = _findCompletionOn(
          task.id,
          date,
          participation.taskCompletions,
        );

        TaskInstanceStatus status;
        if (completion != null) {
          status = TaskInstanceStatus.completed;
        } else if (_isSameDay(date, today)) {
          status = TaskInstanceStatus.today;
        } else if (date.isBefore(today)) {
          status = TaskInstanceStatus.missed;
        } else {
          status = TaskInstanceStatus.upcoming;
        }

        instances.add(ChallengeTaskInstance(
          task: task,
          scheduledDate: date,
          status: status,
          completedAt: completion?.completedAt,
        ));
      }
    }

    // Sort by date descending (newest first)
    instances.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return instances;
  }

  /// Generate dates for a task based on frequency
  List<DateTime> _generateDatesForTask(
    TaskFrequency frequency,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    switch (frequency) {
      case TaskFrequency.daily:
        DateTime current = start;
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          dates.add(current);
          current = current.add(const Duration(days: 1));
        }
        break;

      case TaskFrequency.weekly:
        DateTime current = start; // Start from join date, not 7 days later!
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          dates.add(current);
          current = current.add(const Duration(days: 7));
        }
        break;

      case TaskFrequency.oneTime:
        dates.add(start);
        break;
    }

    return dates;
  }

  /// Find completion record for a specific task on a specific date
  TaskCompletionRecord? _findCompletionOn(
    String taskId,
    DateTime date,
    List<TaskCompletionRecord> completions,
  ) {
    for (final completion in completions) {
      if (completion.taskId == taskId &&
          _isSameDay(completion.completedAt, date)) {
        return completion;
      }
    }
    return null;
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

