import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_repository.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';

class ActivityService {
  final ActivityRepository _repository;

  ActivityService(this._repository);

  /// Fetches available activities for subscription
  Future<List<Activity>> getAvailableActivities() async {
    try {
      return await _repository.getAvailableActivities();
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
}
