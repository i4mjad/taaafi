import 'dart:ui';

import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_repository.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';

class ActivityService {
  final ActivityRepository _repository;
  final Ref ref;

  ActivityService(this._repository, this.ref);

  /// Fetches available activities for subscription
  Future<List<Activity>> getAvailableActivities() async {
    try {
      return await _repository.getAvailableActivities();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes all ongoing activities
  Future<void> deleteAllOngoingActivities() async {
    try {
      await _repository.deleteAllOngoingActivities();
    } catch (e) {
      rethrow;
    }
  }

  /// Subscribes to an activity
  Future<void> subscribeToActivity(
      DateTime startDate, DateTime endDate, String activityId) async {
    try {
      // Validate subscription period
      if (endDate.difference(startDate).inDays > 90) {
        throw Exception('Subscription period cannot exceed 90 days');
      }

      // Check if already subscribed
      final isSubscribed = await _repository.isUserSubscribed(activityId);
      if (isSubscribed) {
        throw Exception('Already subscribed to this activity');
      }

      await _repository.subscribeToActivity(activityId, startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate activity progress
  Future<double> getActivityProgress(
      String activityId, DateTime startDate) async {
    try {
      return await _repository.calculateActivityProgress(activityId, startDate);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all ongoing activities for the current user
  Future<List<OngoingActivity>> getOngoingActivities() async {
    try {
      return await _repository.getOngoingActivities();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets today's tasks from all ongoing activities
  Future<List<OngoingActivityTask>> getTodayTasks() async {
    try {
      return await _repository.getTodayTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Marks a task as completed for today
  Future<void> completeTask(String taskId) async {
    try {
      await _repository.completeTask(taskId);
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if user is subscribed to an activity
  Future<bool> isUserSubscribed(String activityId) async {
    try {
      return await _repository.isUserSubscribed(activityId);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets activity details by ID
  Future<Activity> getActivityById(String activityId) async {
    try {
      return await _repository.getActivityById(activityId);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets detailed information about an ongoing activity
  Future<OngoingActivityDetails> getOngoingActivityDetails(
      String activityId) async {
    try {
      return await _repository.getOngoingActivityDetails(activityId);
    } catch (e) {
      // showErrorSnackbar(e);
      rethrow;
    }
  }

  /// Updates task completion status
  Future<void> updateTaskCompletion(
    String activityId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await _repository.updateTaskCompletion(activityId, taskId, isCompleted);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all tasks from all activities
  Future<List<OngoingActivityTask>> getAllTasks() async {
    try {
      return await _repository.getAllTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Marks an activity and its scheduled tasks as deleted
  Future<void> deleteActivity(String activityId) async {
    try {
      await _repository.deleteActivity(activityId);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates activity dates and reschedules tasks
  Future<void> updateActivityDates(
    String activityId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      await _repository.updateActivityDates(activityId, startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets tasks scheduled for a specific date
  Future<List<OngoingActivityTask>> getTasksByDate(DateTime date) async {
    try {
      return await _repository.getTasksByDate(date);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets tasks scheduled for a specific date range
  Future<List<OngoingActivityTask>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final tasks = await _repository.getTasksByDateRange(startDate, endDate);

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets stream of today's tasks
  Stream<List<OngoingActivityTask>> getTodayTasksStream() {
    try {
      return _repository.getTodayTasksStream();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets stream of ongoing activities
  Stream<List<OngoingActivity>> getOngoingActivitiesStream() {
    try {
      return _repository.getOngoingActivitiesStream();
    } catch (e) {
      rethrow;
    }
  }

  //TODO: review why this is not working when the activity has ended. Also, make sure to handle the case when the activity is finished and the user is trying to extend it.
  Future<void> extendActivity(
      String activityId, Duration period, Locale locale) async {
    try {
      final details = await getOngoingActivityDetails(activityId);
      final now = DateTime.now();

      // Validate dates
      if (now.isBefore(details.startDate)) {
        throw Exception('Cannot extend activity before start date');
      }

      DateTime newEndDate;
      if (now.isAfter(details.endDate)) {
        // If activity has ended, extend from today
        newEndDate = now.add(period);
      } else {
        // If activity is ongoing, extend from end date
        newEndDate = details.endDate.add(period);
      }

      // Validate total duration
      final totalDuration = newEndDate.difference(details.startDate).inDays;
      if (totalDuration > 90) {
        throw Exception('Total activity duration cannot exceed 90 days');
      }

      // Log extension attempt
      ref.read(errorLoggerProvider).logException(
        'Extending activity',
        StackTrace.current,
        context: {
          'activityId': activityId,
          'currentEndDate': details.endDate.toIso8601String(),
          'newEndDate': newEndDate.toIso8601String(),
          'extensionPeriod': period.inDays,
        },
      );

      await _repository.extendActivity(activityId, details.startDate,
          newEndDate, details.scheduledTasks, locale);

      // Log successful extension
      ref.read(errorLoggerProvider).logException(
        'Activity extended successfully',
        StackTrace.current,
        context: {
          'activityId': activityId,
          'newEndDate': newEndDate.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      // Log extension failure
      ref.read(errorLoggerProvider).logException(
        e,
        stackTrace,
        context: {
          'activityId': activityId,
          'period': period.inDays,
        },
      );
      rethrow;
    }
  }
}
