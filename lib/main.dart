import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/app.dart';

import 'package:reboot_app_3/core/di/container.dart';
import 'package:reboot_app_3/firebase_options.dart';

import 'package:reboot_app_3/shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  SetupContainer();

  InitializationSettings initializationSettings = await setupNotifications();
  await setupFirebaseMesagging(initializationSettings);

  runApp(MyApp());
}

Future<void> setupFirebaseMesagging(
    InitializationSettings initializationSettings) async {
  // CustomerIO.registerDeviceToken(deviceToken: firbaseMessagingToken);

  await NotificationService.flutterLocalNotificationsPlugin
      .initialize(initializationSettings);
}

Future<InitializationSettings> setupNotifications() async {
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsiOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  var initializationSettings = InitializationSettings(
      iOS: initializationSettingsiOS, android: initializationSettingsAndroid);
  // ignore: unused_local_variable
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  return initializationSettings;
}
