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
      // For one-time tasks, use challenge start date (createdAt)
      // For daily/weekly, use join date
      final startDate = task.frequency == TaskFrequency.oneTime
          ? challenge.createdAt
          : participation.joinedAt;
      
      // Normalize start date
      final normalizedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      
      final taskDates = _generateDatesForTask(
        task.frequency,
        normalizedStartDate,
        endDate,
      );
      
      // Debug: Ensure today is included for daily/weekly tasks if it's in range
      if (task.frequency != TaskFrequency.oneTime) {
        if ((today.isAfter(normalizedStartDate) || _isSameDay(today, normalizedStartDate)) &&
            (today.isBefore(endDate) || _isSameDay(today, endDate))) {
          if (!taskDates.any((d) => _isSameDay(d, today))) {
            taskDates.add(today);
          }
        }
      }

      for (final date in taskDates) {
        // Normalize the scheduled date for comparison
        final scheduledDate = DateTime(date.year, date.month, date.day);
        
        final completion = _findCompletionOn(
          task.id,
          scheduledDate,
          participation.taskCompletions,
          task.frequency,
        );

        TaskInstanceStatus status;
        if (completion != null) {
          status = TaskInstanceStatus.completed;
        } else if (_isSameDay(scheduledDate, today)) {
          status = TaskInstanceStatus.today;
        } else if (scheduledDate.isBefore(today)) {
          status = TaskInstanceStatus.missed;
        } else {
          status = TaskInstanceStatus.upcoming;
        }

        instances.add(ChallengeTaskInstance(
          task: task,
          scheduledDate: scheduledDate,
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
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    switch (frequency) {
      case TaskFrequency.daily:
        DateTime current = start;
        // Generate all dates from start to end (inclusive)
        while (!current.isAfter(end)) {
          final normalizedDate = DateTime(current.year, current.month, current.day);
          dates.add(normalizedDate);
          current = current.add(const Duration(days: 1));
        }
        // Explicitly ensure today is included if within range
        if ((today.isAfter(start) || _isSameDay(today, start)) && 
            (today.isBefore(end) || _isSameDay(today, end))) {
          if (!dates.any((d) => _isSameDay(d, today))) {
            dates.add(today);
          }
        }
        break;

      case TaskFrequency.weekly:
        DateTime current = start; // Start from join date, not 7 days later!
        // Generate all weekly dates from start to end (inclusive)
        while (!current.isAfter(end)) {
          dates.add(DateTime(current.year, current.month, current.day));
          current = current.add(const Duration(days: 7));
        }
        // For weekly tasks, ensure today is included if it matches the pattern
        // Check if today is on the same weekday and within range
        final daysSinceStart = today.difference(start).inDays;
        if (daysSinceStart >= 0 && daysSinceStart % 7 == 0 && 
            (today.isBefore(end) || _isSameDay(today, end))) {
          if (!dates.any((d) => _isSameDay(d, today))) {
            dates.add(today);
          }
        }
        break;

      case TaskFrequency.oneTime:
        // For one-time tasks, always show on the challenge start date
        // Only include if it's before or equal to the end date
        if (!start.isAfter(end)) {
          dates.add(start);
        }
        break;
    }

    // Sort dates to ensure proper order
    dates.sort();
    return dates;
  }

  /// Find completion record for a specific task on a specific date
  /// For daily/weekly tasks, matches any completion on that date
  /// For one-time tasks, matches any completion (since there's only one instance)
  TaskCompletionRecord? _findCompletionOn(
    String taskId,
    DateTime date,
    List<TaskCompletionRecord> completions,
    TaskFrequency frequency,
  ) {
    // Normalize the target date to just year/month/day
    final targetDate = DateTime(date.year, date.month, date.day);
    
    for (final completion in completions) {
      if (completion.taskId != taskId) continue;
      
      // For one-time tasks, any completion counts (regardless of date)
      if (frequency == TaskFrequency.oneTime) {
        return completion;
      }
      
      // For daily/weekly, match by date (normalize both dates for comparison)
      final completionDate = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );
      
      if (_isSameDay(completionDate, targetDate)) {
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

