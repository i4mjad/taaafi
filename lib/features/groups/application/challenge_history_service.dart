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

    // DEBUG: Print key dates
    print('🔍 ============ TASK HISTORY DEBUG ============');
    print('📅 Current DateTime: $now');
    print('📅 Today (normalized): $today');
    print('📅 Challenge End Date: $endDate');
    print('📅 User Joined At: ${participation.joinedAt}');
    print('📅 Challenge Created At: ${challenge.createdAt}');
    print('📋 Total Tasks: ${challenge.tasks.length}');
    print('✅ Total Completions: ${participation.taskCompletions.length}');
    participation.taskCompletions.forEach((c) {
      print('   - Task ${c.taskId}: completed at ${c.completedAt}');
    });
    print('==========================================\n');

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
      
      print('🔸 Task: "${task.name}" (${task.frequency.name})');
      print('   Start: $normalizedStartDate');
      print('   Generated ${taskDates.length} dates');
      if (taskDates.length <= 10) {
        print('   Dates: ${taskDates.map((d) => '${d.month}/${d.day}').join(', ')}');
      } else {
        print('   First 5: ${taskDates.take(5).map((d) => '${d.month}/${d.day}').join(', ')}...');
        print('   Last 5: ${taskDates.skip(taskDates.length - 5).map((d) => '${d.month}/${d.day}').join(', ')}');
      }
      print('   Today (${today.month}/${today.day}) in dates? ${taskDates.any((d) => _isSameDay(d, today))}');
      
      // Debug: Ensure today is included for daily/weekly tasks if it's in range
      if (task.frequency != TaskFrequency.oneTime) {
        final shouldIncludeToday = (today.isAfter(normalizedStartDate) || _isSameDay(today, normalizedStartDate)) &&
            (today.isBefore(endDate) || _isSameDay(today, endDate));
        print('   Should include today? $shouldIncludeToday');
        if (shouldIncludeToday) {
          if (!taskDates.any((d) => _isSameDay(d, today))) {
            print('   ⚠️  Adding today manually!');
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

    // Sort by date: Show today at top, then descending (past first, then future)
    // Order: Today → Yesterday → 2 days ago → ... → Tomorrow → Day after
    instances.sort((a, b) {
      final aIsToday = _isSameDay(a.scheduledDate, today);
      final bIsToday = _isSameDay(b.scheduledDate, today);
      
      // Today's tasks always first
      if (aIsToday && !bIsToday) return -1;
      if (bIsToday && !aIsToday) return 1;
      
      // For non-today tasks:
      // - Past tasks: closer to today first (descending)
      // - Future tasks: appear after past tasks (descending)
      // This naturally sorts as: today, yesterday, 2 days ago, ..., tomorrow, day after
      final aIsPast = a.scheduledDate.isBefore(today);
      final bIsPast = b.scheduledDate.isBefore(today);
      
      // Both past or both future: descending (most recent first)
      if (aIsPast == bIsPast) {
        return b.scheduledDate.compareTo(a.scheduledDate);
      }
      
      // Past tasks come before future tasks
      return aIsPast ? -1 : 1;
    });

    print('\n📊 Total Instances Generated: ${instances.length}');
    print('🔍 First 5 dates after sort: ${instances.take(5).map((i) => '${i.scheduledDate.month}/${i.scheduledDate.day}/${i.scheduledDate.year} (${i.status.name})').join(', ')}');
    print('🔍 ============ END DEBUG ============\n');

    return instances;
  }

  /// Generate dates for a task based on frequency
  List<DateTime> _generateDatesForTask(
    TaskFrequency frequency,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];
    // Normalize all dates to midnight (year/month/day only)
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    switch (frequency) {
      case TaskFrequency.daily:
        // Generate all dates from start to end (inclusive)
        DateTime current = start;
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          dates.add(DateTime(current.year, current.month, current.day));
          current = current.add(const Duration(days: 1));
        }
        break;

      case TaskFrequency.weekly:
        // Generate weekly dates from start date onwards
        DateTime current = start;
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          dates.add(DateTime(current.year, current.month, current.day));
          current = current.add(const Duration(days: 7));
        }
        break;

      case TaskFrequency.oneTime:
        // One-time task shows on challenge start date
        if (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          dates.add(start);
        }
        break;
    }

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

