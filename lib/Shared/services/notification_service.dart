import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void scheduleDailyNotification(BuildContext context) async {
    print(await flutterLocalNotificationsPlugin.getActiveNotifications());
    flutterLocalNotificationsPlugin.cancelAll();
    tz.initializeTimeZones();

    var scheduledNotificationDateTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (scheduledNotificationDateTime == null) return;

    final newTime = TimeOfDay(
        hour: scheduledNotificationDateTime.hour,
        minute: scheduledNotificationDateTime.minute);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_notif',
      'Channel for Alarm notification',
      icon: 'app_icon',
      playSound: true,
    );

    // Use the updated constructor for iOS notification details
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'a_long_cold_sting.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      "المتابعة اليومية",
      "لا تنس المتابعة اليومية",
      tz.TZDateTime.now(tz.local)
          .add(Duration(hours: newTime.hour, minutes: newTime.minute)),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
