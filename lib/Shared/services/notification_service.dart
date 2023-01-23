import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void scheduleDailyNotification(BuildContext context) async {
    flutterLocalNotificationsPlugin.cancelAll();
    tz.initializeTimeZones();

    var scheduledNotificationDateTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (scheduledNotificationDateTime == null) return;
    final Time newTime = Time(scheduledNotificationDateTime.hour,
        scheduledNotificationDateTime.minute);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_notif', 'Channel for Alarm notification',
        icon: 'app_icon', playSound: true);

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        sound: 'a_long_cold_sting.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true);

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    // ignore: deprecated_member_use
    await flutterLocalNotificationsPlugin.showDailyAtTime(0, "المتابعة اليومية",
        "لا تنس المتابعة اليومية", newTime, platformChannelSpecifics);
  }
}
