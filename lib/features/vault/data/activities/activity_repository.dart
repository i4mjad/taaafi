import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

/// Repository for managing activities and user subscriptions in Firestore
///
/// Handles:
/// - Fetching available activities
/// - Managing user subscriptions
/// - Tracking task completions
/// - Calculating progress
class ActivityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityRepository(this._firestore, this._auth);

  /// Gets the current user ID or throws if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Fetches all available activities with their tasks
  ///
  /// Uses parallel queries to optimize fetching activities and their tasks
  Future<List<Activity>> getAvailableActivities() async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .orderBy('activityName')
          .get();

      final activities = await Future.wait(
        activitiesSnapshot.docs.map((doc) async {
          final activity = Activity.fromFirestore(doc);
          final tasksSnapshot = await doc.reference
              .collection('activityTasks')
              .orderBy('taskName')
              .get();

          final tasks = tasksSnapshot.docs
              .map((taskDoc) => ActivityTask.fromFirestore(taskDoc))
              .toList();

          return Activity(
            id: activity.id,
            name: activity.name,
            description: activity.description,
            difficulty: activity.difficulty,
            subscriberCount: activity.subscriberCount,
            tasks: tasks,
          );
        }),
      );

      return activities;
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  /// Subscribes user to an activity and creates scheduled task documents
  ///
  /// Creates:
  /// - Subscription document with activity details
  /// - Individual scheduled task documents for each task occurrence
  /// - Updates activity subscriber count
  Future<void> subscribeToActivity(
      String activityId, DateTime startDate, DateTime endDate) async {
    try {
      final userId = _getCurrentUserId();
      final batch = _firestore.batch();
      final subscriptionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId);

      // Create subscription document
      batch.set(subscriptionRef, {
        'activityId': activityId,
        'startDate': startDate,
        'endDate': endDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get tasks and create scheduled occurrences
      final tasksSnapshot = await _firestore
          .collection('activities')
          .doc(activityId)
          .collection('activityTasks')
          .get();

      final periodInDays = endDate.difference(startDate).inDays;

      // Create scheduled documents for each task
      for (var task in tasksSnapshot.docs) {
        final frequencyStr = task.data()['taskFrequency'] as String;
        final frequency = _parseTaskFrequency(frequencyStr);
        final scheduledDates = _generateScheduledDates(
          startDate,
          periodInDays,
          frequency,
        );

        // Create documents for each scheduled date
        for (var date in scheduledDates) {
          final taskDocRef = subscriptionRef.collection('scheduledTasks').doc();
          batch.set(
            taskDocRef,
            {
              'taskId': task.id,
              'scheduledDate': date,
              'isCompleted': false,
              'completedAt': null,
            },
          );
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to subscribe to activity: $e');
    }
  }

  /// Parses task frequency string to TaskFrequency enum
  TaskFrequency _parseTaskFrequency(String frequencyStr) {
    try {
      return TaskFrequency.values.firstWhere(
        (f) =>
            f.toString().split('.').last.toLowerCase() ==
            frequencyStr.toLowerCase(),
        orElse: () => TaskFrequency.daily,
      );
    } catch (_) {
      return TaskFrequency.daily;
    }
  }

  /// Generates dates for scheduled tasks based on frequency and period
  List<DateTime> _generateScheduledDates(
      DateTime startDate, int periodInDays, TaskFrequency frequency) {
    final dates = <DateTime>[];
    var currentDate = startDate;
    final endDate = startDate.add(Duration(days: periodInDays));

    while (currentDate.isBefore(endDate)) {
      dates.add(currentDate);
      switch (frequency) {
        case TaskFrequency.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case TaskFrequency.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case TaskFrequency.monthly:
          currentDate = currentDate.add(const Duration(days: 30));
          break;
      }
    }
    return dates;
  }

  /// Checks if current user is subscribed to an activity
  Future<bool> isUserSubscribed(String activityId) async {
    try {
      final userId = _getCurrentUserId();
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Failed to check subscription status: $e');
    }
  }

  /// Calculates activity progress based on completed tasks
  Future<double> calculateActivityProgress(
      String activityId, DateTime startDate) async {
    try {
      final userId = _getCurrentUserId();

      // Get all scheduled tasks for this activity
      final scheduledTasksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .collection('scheduledTasks')
          .get();

      if (scheduledTasksSnapshot.docs.isEmpty) return 0;

      final today = DateTime.now();

      // Count tasks that were scheduled up until now
      final totalScheduledTasks = scheduledTasksSnapshot.docs.where((doc) {
        final scheduledDate =
            (doc.data()['scheduledDate'] as Timestamp).toDate();
        return scheduledDate.isBefore(today);
      }).length;

      // Count completed tasks
      final completedTasks = scheduledTasksSnapshot.docs.where((doc) {
        final scheduledDate =
            (doc.data()['scheduledDate'] as Timestamp).toDate();
        return scheduledDate.isBefore(today) &&
            doc.data()['isCompleted'] == true;
      }).length;

      if (totalScheduledTasks == 0) return 0;

      final progress = (completedTasks / totalScheduledTasks) * 100;

      return progress;
    } catch (e, st) {
      print('Error calculating progress: $e');
      print('Stack trace: $st');
      throw Exception('Failed to calculate progress: $e');
    }
  }

  int _calculateExpectedCompletions(
      TaskFrequency frequency, int daysSinceStart) {
    switch (frequency) {
      case TaskFrequency.daily:
        return daysSinceStart;
      case TaskFrequency.weekly:
        return (daysSinceStart / 7).floor();
      case TaskFrequency.monthly:
        return (daysSinceStart / 30).floor();
    }
  }

  /// Gets all ongoing activities for the current user
  Future<List<OngoingActivity>> getOngoingActivities() async {
    try {
      final userId = _getCurrentUserId();

      // Get ongoing activities
      final ongoingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .get();

      // Get activities and their progress in parallel
      final ongoingActivities = await Future.wait(
        ongoingSnapshot.docs.map((doc) async {
          final ongoingActivity = OngoingActivity.fromFirestore(doc);

          // Get the activity details
          final activityDoc = await _firestore
              .collection('activities')
              .doc(ongoingActivity.activityId)
              .get();

          if (!activityDoc.exists) {
            return null;
          }

          final activity = Activity.fromFirestore(activityDoc);

          // Calculate progress
          final progress = await calculateActivityProgress(
            ongoingActivity.activityId,
            ongoingActivity.startDate,
          );

          return OngoingActivity(
            id: ongoingActivity.id,
            activityId: ongoingActivity.activityId,
            startDate: ongoingActivity.startDate,
            endDate: ongoingActivity.endDate,
            createdAt: ongoingActivity.createdAt,
            activity: activity,
            progress: progress,
          );
        }),
      );

      // Filter out null values and return
      final validActivities =
          ongoingActivities.whereType<OngoingActivity>().toList();
      return validActivities;
    } catch (e, st) {
      print('Error in getOngoingActivities: $e');
      print('Stack trace: $st');
      throw Exception('Failed to fetch ongoing activities: $e');
    }
  }

  /// Gets tasks due today from all ongoing activities
  Future<List<OngoingActivityTask>> getTodayTasks() async {
    try {
      final userId = _getCurrentUserId();
      final today = DateTime.now();

      // Get all ongoing activities
      final ongoingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .get();

      List<OngoingActivityTask> todayTasks = [];

      for (var activityDoc in ongoingSnapshot.docs) {
        final ongoingActivity = OngoingActivity.fromFirestore(activityDoc);

        // Skip if activity hasn't started or has ended
        if (today.isBefore(ongoingActivity.startDate) ||
            today.isAfter(ongoingActivity.endDate)) {
          continue;
        }

        // Get base tasks
        final tasksSnapshot = await _firestore
            .collection('activities')
            .doc(ongoingActivity.activityId)
            .collection('activityTasks')
            .get();

        // Map tasks for lookup
        final tasks = {
          for (var doc in tasksSnapshot.docs)
            doc.id: ActivityTask.fromFirestore(doc)
        };

        // Get scheduled tasks for today
        final todayDate = DateTime(today.year, today.month, today.day);
        final startOfDay = Timestamp.fromDate(
            DateTime(today.year, today.month, today.day, 0, 0, 0));
        final endOfDay = Timestamp.fromDate(
            DateTime(today.year, today.month, today.day, 23, 59, 59));

        final scheduledTasksSnapshot = await activityDoc.reference
            .collection('scheduledTasks')
            .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
            .where('scheduledDate', isLessThanOrEqualTo: endOfDay)
            .get();

        // Add tasks with their scheduled IDs
        for (var scheduledDoc in scheduledTasksSnapshot.docs) {
          final data = scheduledDoc.data();
          final baseTask = tasks[data['taskId']];
          if (baseTask != null) {
            todayTasks.add(OngoingActivityTask(
              task: baseTask,
              taskDatetime: today,
              isCompleted: data['isCompleted'] ?? false,
              scheduledTaskId: scheduledDoc.id,
              activityId: ongoingActivity.activityId,
            ));
          }
        }
      }

      return todayTasks;
    } catch (e) {
      throw Exception('Failed to fetch today\'s tasks: $e');
    }
  }

  /// Marks a task as completed for today
  Future<void> completeTask(String scheduledTaskId) async {
    try {
      final userId = _getCurrentUserId();

      // Find the ongoing activity that contains this scheduled task
      final ongoingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .get();

      for (var activityDoc in ongoingSnapshot.docs) {
        final scheduledTaskRef = activityDoc.reference
            .collection('scheduledTasks')
            .doc(scheduledTaskId);

        final scheduledTaskDoc = await scheduledTaskRef.get();

        if (scheduledTaskDoc.exists) {
          await scheduledTaskRef.update({
            'isCompleted': true,
            'completedAt': FieldValue.serverTimestamp(),
          });
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  bool _isTaskDueToday(TaskFrequency frequency, DateTime startDate) {
    final today = DateTime.now();
    final daysSinceStart = today.difference(startDate).inDays;

    switch (frequency) {
      case TaskFrequency.daily:
        return true;
      case TaskFrequency.weekly:
        return daysSinceStart % 7 == 0;
      case TaskFrequency.monthly:
        return daysSinceStart % 30 == 0;
    }
  }

  /// Fetches a specific activity with its tasks
  ///
  /// Uses an optimized query to fetch the activity and its tasks in parallel
  Future<Activity> getActivityById(String activityId) async {
    try {
      // Get activity document
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = Activity.fromFirestore(activityDoc);

      // Get tasks for this activity
      final tasksSnapshot = await activityDoc.reference
          .collection('activityTasks')
          .orderBy('taskName')
          .get();

      final tasks = tasksSnapshot.docs
          .map((taskDoc) => ActivityTask.fromFirestore(taskDoc))
          .toList();

      return Activity(
        id: activity.id,
        name: activity.name,
        description: activity.description,
        difficulty: activity.difficulty,
        subscriberCount: activity.subscriberCount,
        tasks: tasks,
      );
    } catch (e) {
      throw Exception('Failed to fetch activity: $e');
    }
  }

  /// Gets detailed information about an ongoing activity including performance
  Future<OngoingActivityDetails> getOngoingActivityDetails(
      String activityId) async {
    try {
      final userId = _getCurrentUserId();

      // Get subscription document
      final subscriptionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .get();

      if (!subscriptionDoc.exists) {
        throw Exception('Activity subscription not found');
      }

      // Get activity details
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = Activity.fromFirestore(activityDoc);
      final subscription = OngoingActivity.fromFirestore(subscriptionDoc);

      // Get tasks with their scheduled occurrences
      final tasksSnapshot = await activityDoc.reference
          .collection('activityTasks')
          .orderBy('taskName')
          .get();

      final tasks = tasksSnapshot.docs
          .map((doc) => ActivityTask.fromFirestore(doc))
          .toList();

      // Get last 7 occurrences performance for each task
      final scheduledTasksSnapshot = await subscriptionDoc.reference
          .collection('scheduledTasks')
          .orderBy('scheduledDate', descending: true)
          .get();

      final taskPerformance = <String, List<bool>>{};

      for (var task in tasks) {
        final taskOccurrences = scheduledTasksSnapshot.docs
            .where((doc) => doc.data()['taskId'] == task.id)
            .take(7)
            .map((doc) => doc.data()['isCompleted'] as bool)
            .toList();

        taskPerformance[task.id] = taskOccurrences;
      }

      // Calculate overall progress
      final progress = await calculateActivityProgress(
        activityId,
        subscription.startDate,
      );

      return OngoingActivityDetails(
        activity: activity,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        progress: progress,
        tasks: tasks,
        taskPerformance: taskPerformance,
      );
    } catch (e) {
      throw Exception('Failed to fetch ongoing activity details: $e');
    }
  }

  /// Updates task completion status
  Future<void> updateTaskCompletion(
    String activityId,
    String scheduledTaskId,
    bool isCompleted,
  ) async {
    try {
      final userId = _getCurrentUserId();

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .collection('scheduledTasks')
          .doc(scheduledTaskId);

      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Scheduled task document not found');
      }

      await docRef.update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      throw Exception('Failed to update task completion: $e');
    }
  }

  /// Gets all tasks from all activities
  Future<List<OngoingActivityTask>> getAllTasks() async {
    try {
      final userId = _getCurrentUserId();
      final List<OngoingActivityTask> allTasks = [];

      // Get all ongoing activities
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .get();

      // Process each activity
      for (var activityDoc in activitiesSnapshot.docs) {
        final activityId = activityDoc.data()['activityId'] as String;

        // Get base tasks and map them by ID
        final baseTasks = await _getBaseTasksMap(activityId);

        // Get and process scheduled tasks
        final scheduledTasks = await activityDoc.reference
            .collection('scheduledTasks')
            .orderBy('scheduledDate', descending: true)
            .get();

        // Create task objects
        _processScheduledTasks(
          scheduledTasks.docs,
          baseTasks,
          activityId,
          allTasks,
        );
      }

      return allTasks;
    } catch (e) {
      throw Exception('Failed to fetch all tasks: $e');
    }
  }

  // Helper method to get base tasks map
  Future<Map<String, ActivityTask>> _getBaseTasksMap(String activityId) async {
    final baseTasksSnapshot = await _firestore
        .collection('activities')
        .doc(activityId)
        .collection('activityTasks')
        .get();

    return {
      for (var doc in baseTasksSnapshot.docs)
        doc.id: ActivityTask.fromFirestore(doc)
    };
  }

  // Helper method to process scheduled tasks
  void _processScheduledTasks(
    List<QueryDocumentSnapshot> scheduledDocs,
    Map<String, ActivityTask> baseTasks,
    String activityId,
    List<OngoingActivityTask> allTasks,
  ) {
    for (var doc in scheduledDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final baseTask = baseTasks[data['taskId']];

      if (baseTask != null) {
        allTasks.add(OngoingActivityTask(
          task: baseTask,
          taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] as bool,
          scheduledTaskId: doc.id,
          activityId: activityId,
        ));
      }
    }
  }
}
