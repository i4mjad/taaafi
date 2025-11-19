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
      // IMPORTANT: Weekly tasks use CHALLENGE CREATION DATE as the anchor
      // Daily tasks use USER JOIN DATE as the start
      final DateTime taskScheduleStart;
      
      if (task.frequency == TaskFrequency.weekly) {
        // Weekly tasks are anchored to challenge creation date
        taskScheduleStart = challenge.createdAt;
      } else {
        // Daily tasks start from when user joined
        taskScheduleStart = participation.joinedAt;
      }

      // Normalize start date
      final normalizedStartDate = DateTime(
        taskScheduleStart.year,
        taskScheduleStart.month,
        taskScheduleStart.day,
      );

      final taskDates = _generateDatesForTask(
        task.frequency,
        normalizedStartDate,
        endDate,
      );
      
      // Filter out dates before user joined (they can't complete tasks before joining!)
      final userJoinDate = DateTime(
        participation.joinedAt.year,
        participation.joinedAt.month,
        participation.joinedAt.day,
      );
      
      final availableDates = taskDates.where((date) {
        return date.isAfter(userJoinDate) || _isSameDay(date, userJoinDate);
      }).toList();

      print('🔸 Task: "${task.name}" (${task.frequency.name})');
      print('   Task schedule start: $normalizedStartDate');
      print('   User joined: $userJoinDate');
      print('   Generated ${taskDates.length} dates, ${availableDates.length} available after join');
      if (availableDates.length <= 10) {
        print(
            '   Available dates: ${availableDates.map((d) => '${d.month}/${d.day}').join(', ')}');
      } else {
        print(
            '   First 5: ${availableDates.take(5).map((d) => '${d.month}/${d.day}').join(', ')}...');
        print(
            '   Last 5: ${availableDates.skip(availableDates.length - 5).map((d) => '${d.month}/${d.day}').join(', ')}');
      }
      print(
          '   Today (${today.month}/${today.day}) in dates? ${availableDates.any((d) => _isSameDay(d, today))}');

      // DO NOT manually add today for weekly tasks - respect the 7-day interval!
      // Only add today for daily tasks if somehow missing
      if (task.frequency == TaskFrequency.daily) {
        final shouldIncludeToday = (today.isAfter(userJoinDate) ||
                _isSameDay(today, userJoinDate)) &&
            (today.isBefore(endDate) || _isSameDay(today, endDate));
        print('   Should include today? $shouldIncludeToday');
        if (shouldIncludeToday) {
          if (!availableDates.any((d) => _isSameDay(d, today))) {
            print('   ⚠️  Adding today manually for daily task!');
            availableDates.add(today);
          }
        }
      }

      for (final date in availableDates) {
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

    // Sort by absolute distance from today (closest dates first)
    // Order: Today → Yesterday → Tomorrow → 2 days ago → 2 days from now → etc.
    instances.sort((a, b) {
      final aIsToday = _isSameDay(a.scheduledDate, today);
      final bIsToday = _isSameDay(b.scheduledDate, today);

      // Today's tasks always first
      if (aIsToday && !bIsToday) return -1;
      if (bIsToday && !aIsToday) return 1;

      // For non-today tasks, sort by absolute distance from today
      final aDiff = a.scheduledDate.difference(today).inDays.abs();
      final bDiff = b.scheduledDate.difference(today).inDays.abs();

      // If same distance (e.g., yesterday and tomorrow), prefer past over future
      if (aDiff == bDiff) {
        return a.scheduledDate.isBefore(today) ? -1 : 1;
      }

      // Otherwise, closer dates first
      return aDiff.compareTo(bDiff);
    });

    print('\n📊 Total Instances Generated: ${instances.length}');
    print(
        '🔍 First 5 dates after sort: ${instances.take(5).map((i) => '${i.scheduledDate.month}/${i.scheduledDate.day}/${i.scheduledDate.year} (${i.status.name})').join(', ')}');
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

      // Match by date (normalize both dates for comparison)
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

  /// Generate ONLY today's task instances (more efficient for "today's tasks" view)
  /// This method doesn't generate full history - only checks if tasks are due today
  List<ChallengeTaskInstance> generateTodayTaskInstances({
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

    // Check if challenge is still active
    if (today.isAfter(endDate)) {
      return instances; // Challenge ended, no tasks for today
    }

    for (final task in challenge.tasks) {
      // Check if task is due today based on frequency
      // Use challenge creation date for task start, but user must have joined
      final isDueToday = _isTaskDueToday(
        task: task,
        challengeCreatedAt: challenge.createdAt,
        userJoinedAt: participation.joinedAt,
        today: today,
        endDate: endDate,
      );

      if (isDueToday) {
        // Check if completed today
        final completion = _findCompletionOn(
          task.id,
          today,
          participation.taskCompletions,
          task.frequency,
        );

        // Only add if NOT completed - completed tasks should not appear in "today's tasks"
        if (completion == null) {
          instances.add(ChallengeTaskInstance(
            task: task,
            scheduledDate: today,
            status: TaskInstanceStatus.today,
            completedAt: null,
          ));
        }
      }
    }

    return instances;
  }

  /// Check if a task is due today based on its frequency
  bool _isTaskDueToday({
    required ChallengeTaskEntity task,
    required DateTime challengeCreatedAt,
    required DateTime userJoinedAt,
    required DateTime today,
    required DateTime endDate,
  }) {
    // Normalize dates
    final normalizedChallengeStart = DateTime(
      challengeCreatedAt.year,
      challengeCreatedAt.month,
      challengeCreatedAt.day,
    );
    
    final normalizedJoinDate = DateTime(
      userJoinedAt.year,
      userJoinedAt.month,
      userJoinedAt.day,
    );

    // User must have joined to see tasks
    final hasUserJoined = today.isAfter(normalizedJoinDate) ||
        _isSameDay(today, normalizedJoinDate);
    
    // Check if today is within challenge range
    final isBeforeEnd = today.isBefore(endDate) || _isSameDay(today, endDate);

    if (!hasUserJoined || !isBeforeEnd) {
      return false; // User hasn't joined yet or challenge ended
    }

    switch (task.frequency) {
      case TaskFrequency.daily:
        // Daily tasks are due every day (but only after user joined)
        return true;

      case TaskFrequency.weekly:
        // Weekly tasks repeat every 7 days FROM CHALLENGE CREATION DATE
        // NOT from user join date!
        final daysSinceChallengeStart = today.difference(normalizedChallengeStart).inDays;
        
        // Task is due if it's exactly N weeks from challenge start
        return daysSinceChallengeStart % 7 == 0;
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
