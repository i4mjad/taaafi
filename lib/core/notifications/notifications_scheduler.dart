import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// Replace with your own model definitions

class NotificationsScheduler {
  // Singleton
  NotificationsScheduler._();
  static final NotificationsScheduler instance = NotificationsScheduler._();

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final onClickNotification = BehaviorSubject<String>();

  final Map<String, List<int>> _activityNotificationsMap = {};
  static const String _prefsMapKey = 'activityNotificationMap';

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    description: 'This channel is used for important notifications',
  );

  Future<void> init() async {
    final androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = const DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    tz.initializeTimeZones();

    // Load existing map from SharedPreferences
    await _loadActivityNotificationMapFromStorage();
  }

  void _onNotificationTap(NotificationResponse notificationResponse) {
    onClickNotification.add(notificationResponse.payload ?? '');
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(1000000000);
  }

  Future<void> _loadActivityNotificationMapFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedString = prefs.getString(_prefsMapKey);
    if (storedString != null) {
      try {
        final jsonMap = jsonDecode(storedString) as Map<String, dynamic>;
        final mapped = jsonMap.map<String, List<int>>((key, value) {
          final listDynamic = value as List<dynamic>;
          final listOfInts = listDynamic.map((e) => e as int).toList();
          return MapEntry(key, listOfInts);
        });
        _activityNotificationsMap.clear();
        _activityNotificationsMap.addAll(mapped);
      } catch (e) {
        print('Error parsing SharedPreferences JSON: $e');
      }
    }
  }

  Future<void> _saveActivityNotificationMapToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_activityNotificationsMap);
    await prefs.setString(_prefsMapKey, jsonString);
  }

  // ----------------------------------------------------------
  // Schedule a single notification
  Future<void> showScheduleNotification({
    required int notificationId,
    required String title,
    required String body,
    required String payload,
    required DateTime scheduledDate,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ----------------------------------------------------------
  // Show an immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    final int notificationId = _generateNotificationId();
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ----------------------------------------------------------
  // Check if an OngoingActivity has scheduled notifications
  bool hasScheduledNotifications(String ongoingActivityId) {
    final ids = _activityNotificationsMap[ongoingActivityId];
    return ids != null && ids.isNotEmpty;
  }

  bool hasScheduledNotificationsForActivity(OngoingActivity activity) {
    return hasScheduledNotifications(activity.id);
  }

  // ----------------------------------------------------------
  // Schedule notifications for a single OngoingActivity
  Future<void> scheduleNotificationsForOngoingActivity(
      OngoingActivity ongoingActivity, Locale locale) async {
    final String ongoingActivityId = ongoingActivity.id;
    final List<int> notificationIds = [];

    for (final scheduledTask in ongoingActivity.scheduledTasks) {
      if (scheduledTask.taskDatetime.isAfter(DateTime.now())) {
        final int id = _generateNotificationId();
        await showScheduleNotification(
          notificationId: id,
          title: ongoingActivity.activity!.name,
          body: scheduledTask.task.name,
          payload: ongoingActivityId,
          scheduledDate: scheduledTask.taskDatetime,
        );
        notificationIds.add(id);
      }
    }

    // Store these IDs
    _activityNotificationsMap[ongoingActivityId] = notificationIds;
    await _saveActivityNotificationMapToStorage();
  }

  // ----------------------------------------------------------
  // Schedule notifications for a list of activities
  Future<void> scheduleNotificationsForOngoingActivities(
      List<OngoingActivity> activities, Locale locale) async {
    for (final ongoingActivity in activities) {
      await scheduleNotificationsForOngoingActivity(ongoingActivity, locale);
    }
  }

  // ----------------------------------------------------------
  // Cancel all notifications by OngoingActivity ID
  Future<void> cancelNotificationsForActivity(String ongoingActivityId) async {
    final notificationIds = _activityNotificationsMap[ongoingActivityId];
    if (notificationIds == null) return;

    for (final id in notificationIds) {
      await _flutterLocalNotificationsPlugin.cancel(id);
    }

    _activityNotificationsMap.remove(ongoingActivityId);
    await _saveActivityNotificationMapToStorage();
  }

  // Optional: Cancel by the OngoingActivity object
  Future<void> cancelNotificationsForActivityObject(
      OngoingActivity ongoingActivity) async {
    await cancelNotificationsForActivity(ongoingActivity.id);
  }

  // ----------------------------------------------------------
  // Cancel a single notification by ID
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    // If you want to remove the ID from _activityNotificationsMap,
    // do a reverse lookup here. E.g.:
    final entry = _activityNotificationsMap.entries.firstWhere(
      (e) => e.value.contains(id),
      orElse: () => MapEntry('', []),
    );
    if (entry.key.isNotEmpty) {
      entry.value.remove(id);
      if (entry.value.isEmpty) {
        _activityNotificationsMap.remove(entry.key);
      }
      await _saveActivityNotificationMapToStorage();
    }
  }

  // ----------------------------------------------------------
  // Cancel ALL notifications
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _activityNotificationsMap.clear();
    await _saveActivityNotificationMapToStorage();
  }
}
