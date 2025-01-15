import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/notifications/notifications_scheduler.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_details.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';

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
  final AnalyticsFacade _analytics;
  final Ref ref;

  ActivityRepository(this._firestore, this._auth, this._analytics, this.ref);

  /// Gets the current user ID or throws if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Deletes all ongoing activities and their subscription sessions
  Future<void> deleteAllOngoingActivities() async {
    try {
      final userId = _getCurrentUserId();
      final batch = _firestore.batch();

      // Get all ongoing activities
      final ongoingActivities = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .get();

      // For each ongoing activity
      for (var activityDoc in ongoingActivities.docs) {
        final activityId = activityDoc.data()['activityId'] as String;

        // Delete the subscription session for this activity
        final subscriptionRef = _firestore
            .collection('activities')
            .doc(activityId)
            .collection('subscriptionSessions')
            .doc(userId);
        batch.delete(subscriptionRef);

        // Delete all scheduled tasks for this activity
        final scheduledTasksSnapshot =
            await activityDoc.reference.collection('scheduledTasks').get();

        for (var taskDoc in scheduledTasksSnapshot.docs) {
          batch.delete(taskDoc.reference);
        }

        // Delete the ongoing activity document itself
        batch.delete(activityDoc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all activities: $e');
    }
  }

  /// Fetches all available activities with their tasks
  ///
  /// Uses parallel queries to optimize fetching activities and their tasks
  Future<List<Activity>> getAvailableActivities() async {
    unawaited(_analytics.trackActivityFetchStarted());
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .orderBy('activityName')
          .get();

      final activities = await Future.wait(
        activitiesSnapshot.docs.map((doc) async {
          final activity = Activity.fromFirestore(doc);

          // Get subscriber count from subscriptionSessions collection
          final subscriberCount = await doc.reference
              .collection('subscriptionSessions')
              .count()
              .get()
              .then((value) => value.count);

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
            subscriberCount: subscriberCount ?? 0, // Use actual count
            tasks: tasks,
          );
        }),
      );

      unawaited(_analytics.trackActivityFetchFinished());
      return activities;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      unawaited(_analytics.trackActivityFetchFailed());
      rethrow;
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
    unawaited(_analytics.trackActivitySubscriptionStarted());
    try {
      final userId = _getCurrentUserId();
      // Create a batch to handle multiple writes atomically
      final batch = _firestore.batch();

      // Reference to the user's ongoing activity document
      final subscriptionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId);

      // Create the main subscription document with activity metadata
      batch.set(subscriptionRef, {
        'activityId': activityId,
        'startDate': startDate,
        'endDate': endDate,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create subscription tracking document in the base activity
      final sessionRef = _firestore
          .collection('activities')
          .doc(activityId)
          .collection('subscriptionSessions')
          .doc(userId);

      // Store user's subscription session details
      batch.set(sessionRef, {
        'userId': userId,
        'startDate': startDate,
        'endDate': endDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fetch all tasks associated with this activity
      final tasksSnapshot = await _firestore
          .collection('activities')
          .doc(activityId)
          .collection('activityTasks')
          .get();

      // Calculate total subscription period
      final periodInDays = endDate.difference(startDate).inDays;

      // For each task in the activity
      for (var task in tasksSnapshot.docs) {
        // Get task frequency from the task document
        final frequencyStr = task.data()['taskFrequency'] as String;
        // Convert string frequency to enum
        final frequency = _parseTaskFrequency(frequencyStr);
        // Generate all dates this task should occur on
        final scheduledDates = _generateScheduledDates(
          startDate,
          periodInDays,
          frequency,
        );

        // Create a scheduled task document for each occurrence date
        for (var date in scheduledDates) {
          final taskDocRef = subscriptionRef.collection('scheduledTasks').doc();
          batch.set(
            taskDocRef,
            {
              'taskId': task.id,
              'scheduledDate': date,
              'isDeleted': false,
              'isCompleted': false,
              'completedAt': null,
            },
          );
        }
      }

      // Commit all the batch operations
      await batch.commit();

      unawaited(_analytics.trackActivitySubscriptionFinished());
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      unawaited(_analytics.trackActivitySubscriptionFailed());
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
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
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

      if (docSnapshot.exists && docSnapshot.data()?['isDeleted'] == false) {
        return true;
      } else {
        return false;
      }

      return docSnapshot.exists;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to check subscription status: $e');
    }
  }

  /// Calculate activity progress considering only non-deleted tasks
  Future<double> calculateActivityProgress(
    String activityId,
    DateTime startDate,
  ) async {
    unawaited(_analytics.trackProgressCalculationStarted());
    try {
      final userId = _getCurrentUserId();
      final now = DateTime.now().add(const Duration(days: 1));

      // Get all scheduled tasks up to now that aren't deleted
      final scheduledTasksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .collection('scheduledTasks')
          .where('isDeleted', isEqualTo: false)
          .where('scheduledDate',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
          .get();

      if (scheduledTasksSnapshot.docs.isEmpty) {
        return 0.0;
      }

      // Count completed tasks from past and today only
      final completedTasks = scheduledTasksSnapshot.docs.where((doc) {
        final taskDate = (doc.data()['scheduledDate'] as Timestamp).toDate();
        return !taskDate.isAfter(now) && doc.data()['isCompleted'] == true;
      }).length;

      // Count total tasks up to now (excluding future tasks)
      final totalTasksUntilNow = scheduledTasksSnapshot.docs.where((doc) {
        final taskDate = (doc.data()['scheduledDate'] as Timestamp).toDate();
        return !taskDate.isAfter(now);
      }).length;

      // Calculate progress percentage
      final progress = completedTasks / totalTasksUntilNow * 100;

      unawaited(_analytics.trackProgressCalculationFinished());
      return progress;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      unawaited(_analytics.trackProgressCalculationFailed());
      throw Exception('Failed to calculate activity progress: $e');
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
          .where('isDeleted', isEqualTo: false)
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

          final scheduledTasks = await _getScheduledTasks(ongoingActivity.id);

          return OngoingActivity(
            id: ongoingActivity.id,
            activityId: ongoingActivity.activityId,
            startDate: ongoingActivity.startDate,
            endDate: ongoingActivity.endDate,
            createdAt: ongoingActivity.createdAt,
            activity: activity,
            scheduledTasks: scheduledTasks,
            progress: progress,
          );
        }),
      );

      // Filter out null values and return
      final validActivities =
          ongoingActivities.whereType<OngoingActivity>().toList();
      return validActivities;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to fetch ongoing activities: $e');
    }
  }

  /// Gets tasks due today from all ongoing activities
  Future<List<OngoingActivityTask>> getTodayTasks() async {
    try {
      final userId = _getCurrentUserId();
      final today = DateTime.now();

      final ongoingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .where('isDeleted', isEqualTo: false)
          .get();

      List<OngoingActivityTask> todayTasks = [];

      for (var activityDoc in ongoingSnapshot.docs) {
        final ongoingActivity = OngoingActivity.fromFirestore(activityDoc);

        // Skip if activity hasn't started or has ended
        if (today.isBefore(DateTime(
                ongoingActivity.startDate.year,
                ongoingActivity.startDate.month,
                ongoingActivity.startDate.day)) ||
            today.isAfter(DateTime(ongoingActivity.endDate.year,
                ongoingActivity.endDate.month, ongoingActivity.endDate.day))) {
          continue;
        }

        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay =
            DateTime(today.year, today.month, today.day, 23, 59, 59);

        final tasksQuery = activityDoc.reference
            .collection('scheduledTasks')
            .where('isDeleted', isEqualTo: false)
            .where('scheduledDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('scheduledDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));

        final scheduledTasksSnapshot = await tasksQuery.get();

        // Get base tasks for mapping
        final baseTasks = await _getBaseTasksMap(ongoingActivity.activityId);

        // Add tasks with their scheduled IDs
        for (var scheduledDoc in scheduledTasksSnapshot.docs) {
          final data = scheduledDoc.data();
          final baseTask = baseTasks[data['taskId']];
          if (baseTask != null) {
            todayTasks.add(OngoingActivityTask(
              id: scheduledDoc.id,
              task: baseTask,
              taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
              isCompleted: data['isCompleted'] ?? false,
              scheduledTaskId: scheduledDoc.id,
              activityId: ongoingActivity.activityId,
            ));
          }
        }
      }

      return todayTasks;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
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
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to complete task: $e');
    }
  }

  /// Fetches a specific activity with its tasks
  ///
  /// Uses an optimized query to fetch the activity and its tasks in parallel
  Future<Activity> getActivityById(String activityId) async {
    try {
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = Activity.fromFirestore(activityDoc);

      // Get subscriber count from subscriptionSessions collection
      final subscriberCount = await activityDoc.reference
          .collection('subscriptionSessions')
          .count()
          .get()
          .then((value) => value.count);

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
        subscriberCount: subscriberCount ?? 0, // Use actual count
        tasks: tasks,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to fetch activity: $e');
    }
  }

  /// Gets detailed information about an ongoing activity including performance
  Future<OngoingActivityDetails> getOngoingActivityDetails(
      String activityId) async {
    print("entered here");
    try {
      final userId = _getCurrentUserId();
      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final baseActivityId = activityDoc.data()?['activityId'] as String;
      final baseActivityDoc =
          await _firestore.collection('activities').doc(baseActivityId).get();

      // Get subscriber count from subscriptionSessions collection
      final subscriberCount = await baseActivityDoc.reference
          .collection('subscriptionSessions')
          .count()
          .get()
          .then((value) => value.count ?? 0);

      final activity = Activity.fromFirestore(baseActivityDoc);
      final subscription = OngoingActivity.fromFirestore(activityDoc);

      // Get all scheduled tasks with isDeleted filter
      final scheduledTasksSnapshot = await activityDoc.reference
          .collection('scheduledTasks')
          .where('isDeleted', isEqualTo: false)
          .get();

      // Get base tasks for mapping
      final tasksSnapshot = await baseActivityDoc.reference
          .collection('activityTasks')
          .orderBy('taskName')
          .get();

      final baseTasks = {
        for (var doc in tasksSnapshot.docs)
          doc.id: ActivityTask.fromFirestore(doc)
      };

      // Create OngoingActivityTasks
      final tasks = scheduledTasksSnapshot.docs.map((doc) {
        final data = doc.data();
        final baseTask = baseTasks[data['taskId']]!;
        return OngoingActivityTask(
          id: doc.id,
          task: baseTask,
          taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] ?? false,
          scheduledTaskId: doc.id,
          activityId: activityId,
        );
      }).toList();

      // Calculate progress
      final progress =
          await calculateActivityProgress(activityId, subscription.startDate);

      // Get performance data
      final taskPerformance = <String, List<bool>>{};
      for (var task in baseTasks.values) {
        final taskOccurrences = scheduledTasksSnapshot.docs
            .where((doc) => doc.data()['taskId'] == task.id)
            .take(7)
            .map((doc) => doc.data()['isCompleted'] as bool? ?? false)
            .toList();

        taskPerformance[task.id] = taskOccurrences;
      }

      return OngoingActivityDetails(
        activity: activity,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        progress: progress,
        activityTasks: baseTasks.values.toList(),
        scheduledTasks: tasks,
        taskPerformance: taskPerformance,
        subscriberCount: subscriberCount,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
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

      // Prevent completing future tasks
      final scheduledDate =
          (doc.data()?['scheduledDate'] as Timestamp).toDate();
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (scheduledDate.isAfter(endOfToday)) {
        throw Exception('Cannot complete future tasks');
      }

      await docRef.update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
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

        // Get and process scheduled tasks with isDeleted filter
        final scheduledTasks = await activityDoc.reference
            .collection('scheduledTasks')
            .where('isDeleted', isEqualTo: false)
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
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
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
          id: doc.id,
          task: baseTask,
          taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] as bool,
          scheduledTaskId: doc.id,
          activityId: activityId,
        ));
      }
    }
  }

  /// Updates activity dates and recreates scheduled tasks
  Future<void> updateActivityDates(
    String activityId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _getCurrentUserId();
      // Create batch for atomic operations
      final batch = _firestore.batch();

      // Reference to the ongoing activity document
      final activityRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId);

      // Verify activity exists
      final activityDoc = await activityRef.get();
      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      // Get the original activity ID
      final baseActivityId = activityDoc.data()?['activityId'] as String;

      // Update the activity dates
      batch.update(activityRef, {
        'startDate': startDate,
        'endDate': endDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete all existing scheduled tasks
      final existingTasks =
          await activityRef.collection('scheduledTasks').get();
      for (var doc in existingTasks.docs) {
        batch.delete(doc.reference);
      }

      // Commit the deletion batch
      await batch.commit();

      // Get tasks from the original activity template
      final baseActivityDoc =
          await _firestore.collection('activities').doc(baseActivityId).get();

      if (!baseActivityDoc.exists) {
        throw Exception('Base activity not found');
      }

      // Fetch all task templates
      final tasksSnapshot =
          await baseActivityDoc.reference.collection('activityTasks').get();

      final periodInDays = endDate.difference(startDate).inDays;

      // Create new batch for creating new tasks
      final newBatch = _firestore.batch();

      // Create new scheduled tasks for each task template
      for (var task in tasksSnapshot.docs) {
        final frequencyStr = task.data()['taskFrequency'] as String;
        final frequency = _parseTaskFrequency(frequencyStr);
        // Generate new schedule dates
        final scheduledDates = _generateScheduledDates(
          startDate,
          periodInDays,
          frequency,
        );

        // Create new task documents for each date
        for (var date in scheduledDates) {
          final taskDocRef = activityRef.collection('scheduledTasks').doc();
          newBatch.set(taskDocRef, {
            'taskId': task.id,
            'scheduledDate': date,
            'isCompleted': false,
            'completedAt': null,
            'isDeleted': false,
          });
        }
      }

      // Commit the new tasks batch
      await newBatch.commit();

      // Update the subscription session document
      final sessionRef = _firestore
          .collection('activities')
          .doc(baseActivityId)
          .collection('subscriptionSessions')
          .doc(userId);

      batch.update(sessionRef, {
        'startDate': startDate,
        'endDate': endDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to update activity: $e');
    }
  }

  /// Deletes an activity and all associated documents
  Future<void> deleteActivity(String activityId) async {
    try {
      final userId = _getCurrentUserId();
      final batch = _firestore.batch();

      // Get the original activity document to find base activity ID
      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId)
          .get();

      final baseActivityId = activityDoc.data()?['activityId'] as String;

      // Delete the subscription session document
      final sessionRef = _firestore
          .collection('activities')
          .doc(baseActivityId)
          .collection('subscriptionSessions')
          .doc(userId);

      batch.delete(sessionRef);

      // Reference to the ongoing activity
      final activityRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId);

      // Delete all scheduled tasks
      final scheduledTasksSnapshot =
          await activityRef.collection('scheduledTasks').get();
      for (var doc in scheduledTasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the main activity document
      batch.delete(activityRef);

      // Commit all deletions
      await batch.commit();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Gets tasks scheduled for a specific date
  Future<List<OngoingActivityTask>> getTasksByDate(DateTime date) async {
    try {
      final userId = _getCurrentUserId();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final ongoingActivities = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .where('isDeleted', isEqualTo: false)
          .get();

      List<OngoingActivityTask> tasks = [];

      for (var activityDoc in ongoingActivities.docs) {
        final scheduledTasks = await activityDoc.reference
            .collection('scheduledTasks')
            .where('scheduledDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('scheduledDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('isDeleted', isEqualTo: false)
            .get();

        final baseTasks = await _getBaseTasksMap(activityDoc.id);

        for (var taskDoc in scheduledTasks.docs) {
          final data = taskDoc.data();
          final baseTask = baseTasks[data['taskId']];
          if (baseTask != null) {
            tasks.add(OngoingActivityTask(
              id: taskDoc.id,
              task: baseTask,
              taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
              isCompleted: data['isCompleted'] ?? false,
              scheduledTaskId: taskDoc.id,
              activityId: activityDoc.id,
            ));
          }
        }
      }

      return tasks;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to fetch tasks by date: $e');
    }
  }

  /// Gets tasks scheduled for a specific date range
  Future<List<OngoingActivityTask>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _getCurrentUserId();

      final ongoingActivities = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .where('isDeleted', isEqualTo: false)
          .get();

      List<OngoingActivityTask> tasks = [];

      for (var activityDoc in ongoingActivities.docs) {
        final scheduledTasks = await activityDoc.reference
            .collection('scheduledTasks')
            .where('scheduledDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('scheduledDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .where('isDeleted', isEqualTo: false)
            .get();

        final baseTasks = await _getBaseTasksMap(activityDoc.id);

        for (var taskDoc in scheduledTasks.docs) {
          final data = taskDoc.data();
          final baseTask = baseTasks[data['taskId']];
          if (baseTask != null) {
            tasks.add(OngoingActivityTask(
              id: taskDoc.id,
              task: baseTask,
              taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
              isCompleted: data['isCompleted'] ?? false,
              scheduledTaskId: taskDoc.id,
              activityId: activityDoc.id,
            ));
          } else {}
        }
      }

      return tasks;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to fetch tasks by date range: $e');
    }
  }

  /// Stream of today's tasks
  Stream<List<OngoingActivityTask>> getTodayTasksStream() {
    final userId = _getCurrentUserId();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ongoing_activities')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .asyncMap((activities) async {
      List<OngoingActivityTask> todayTasks = [];

      for (var activityDoc in activities.docs) {
        final ongoingActivity = OngoingActivity.fromFirestore(activityDoc);

        if (!_isActivityActive(ongoingActivity, today)) continue;

        final tasksStream = await activityDoc.reference
            .collection('scheduledTasks')
            .where('isDeleted', isEqualTo: false)
            .where('scheduledDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('scheduledDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        final baseTasks = await _getBaseTasksMap(ongoingActivity.activityId);

        for (var scheduledDoc in tasksStream.docs) {
          final data = scheduledDoc.data();
          final baseTask = baseTasks[data['taskId']];
          if (baseTask != null) {
            todayTasks.add(OngoingActivityTask(
              id: scheduledDoc.id,
              task: baseTask,
              taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
              isCompleted: data['isCompleted'] ?? false,
              scheduledTaskId: scheduledDoc.id,
              activityId: ongoingActivity.activityId,
            ));
          }
        }
      }

      return todayTasks;
    });
  }

  /// Stream of ongoing activities
  Stream<List<OngoingActivity>> getOngoingActivitiesStream() {
    final userId = _getCurrentUserId();

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ongoing_activities')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final ongoingActivities = await Future.wait(
        snapshot.docs.map((doc) async {
          final ongoingActivity = OngoingActivity.fromFirestore(doc);

          final activityDoc = await _firestore
              .collection('activities')
              .doc(ongoingActivity.activityId)
              .get();

          if (!activityDoc.exists) return null;

          final activity = Activity.fromFirestore(activityDoc);
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

      return ongoingActivities.whereType<OngoingActivity>().toList();
    });
  }

  bool _isActivityActive(OngoingActivity activity, DateTime date) {
    final startOfDay = DateTime(activity.startDate.year,
        activity.startDate.month, activity.startDate.day);
    final endOfDay = DateTime(
        activity.endDate.year, activity.endDate.month, activity.endDate.day);
    return !date.isBefore(startOfDay) && !date.isAfter(endOfDay);
  }

  Future<List<OngoingActivityTask>> _getScheduledTasks(
      String activityId) async {
    final userId = _getCurrentUserId();
    final scheduledTasksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('ongoing_activities')
        .doc(activityId)
        .collection('scheduledTasks')
        .where('isDeleted', isEqualTo: false)
        .get();

    final baseTasks = await _getBaseTasksMap(activityId);
    final tasks = <OngoingActivityTask>[];

    for (var doc in scheduledTasksSnapshot.docs) {
      final data = doc.data();
      final baseTask = baseTasks[data['taskId']];
      if (baseTask != null) {
        tasks.add(OngoingActivityTask(
          id: doc.id,
          task: baseTask,
          taskDatetime: (data['scheduledDate'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] ?? false,
          scheduledTaskId: doc.id,
          activityId: activityId,
        ));
      }
    }

    return tasks;
  }

  Future<void> extendActivity(
    String activityId,
    DateTime startDate,
    DateTime newEndDate,
    List<OngoingActivityTask> existingTasks,
    Locale locale,
  ) async {
    try {
      final userId = _getCurrentUserId();
      final batch = _firestore.batch();
      final activityRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ongoing_activities')
          .doc(activityId);

      // Get the base activity tasks
      final baseActivityId =
          (await activityRef.get()).data()?['activityId'] as String;
      final tasksSnapshot = await _firestore
          .collection('activities')
          .doc(baseActivityId)
          .collection('activityTasks')
          .get();

      // Update activity end date
      batch.update(activityRef, {
        'endDate': newEndDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the last scheduled date for each task
      final lastScheduledDates = <String, DateTime>{};
      for (var task in existingTasks) {
        final currentLastDate = lastScheduledDates[task.task.id] ?? DateTime(0);
        if (task.taskDatetime.isAfter(currentLastDate)) {
          lastScheduledDates[task.task.id] = task.taskDatetime;
        }
      }

      // Schedule new tasks
      for (var taskDoc in tasksSnapshot.docs) {
        final taskId = taskDoc.id;
        final frequency =
            _parseTaskFrequency(taskDoc.data()['taskFrequency'] as String);

        DateTime startingPoint;
        if (DateTime.now().isAfter(lastScheduledDates[taskId] ?? DateTime(0))) {
          startingPoint = DateTime.now();
        } else {
          startingPoint = lastScheduledDates[taskId]!;
        }

        final scheduledDates = _generateScheduledDates(
          startingPoint,
          newEndDate.difference(startingPoint).inDays,
          frequency,
        );

        for (var date in scheduledDates) {
          if (date.isAfter(startingPoint)) {
            final taskDocRef = activityRef.collection('scheduledTasks').doc();
            batch.set(taskDocRef, {
              'taskId': taskId,
              'scheduledDate': date,
              'isCompleted': false,
              'completedAt': null,
              'isDeleted': false,
            });
          }
        }
      }

      await batch.commit();

      // Reset and reschedule notifications
      await NotificationsScheduler.instance
          .cancelNotificationsForActivity(activityId);

      // Get updated scheduled tasks
      final updatedTasks = await getOngoingActivityDetails(activityId);

      // Schedule new notifications only for future tasks
      await NotificationsScheduler.instance
          .scheduleNotificationsForOngoingActivity(
        OngoingActivity(
          id: activityId,
          activityId: baseActivityId,
          startDate: startDate,
          endDate: newEndDate,
          scheduledTasks: updatedTasks.scheduledTasks,
          activity: updatedTasks.activity,
          createdAt: DateTime.now(),
        ),
        // You'll need to pass the current locale here
        locale,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      throw Exception('Failed to extend activity: $e');
    }
  }
}
