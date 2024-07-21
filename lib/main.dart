import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/app.dart';
import 'package:reboot_app_3/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initalize Firebase
  await initFirebase();

  //TODO: Investigate about what is the best way to update the user FCM token every time the app got initailized

  //TODO: Investigate about a way to update the devices list in user document

  //Initialize Notification settings
  InitializationSettings initializationSettings = await setupNotifications();
  await setupFirebaseMesagging(initializationSettings);

  //Setup error handeling pages
  registerErrorHandlers();
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> setupFirebaseMesagging(
    InitializationSettings initializationSettings) async {
  // CustomerIO.registerDeviceToken(deviceToken: firbaseMessagingToken);
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

void registerErrorHandlers() {
  // * Show some error UI if any uncaught exception happens
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError;
    debugPrint(details.toString());
  };
  // * Handle errors from the underlying platform/OS
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint(error.toString());
    return true;
  };
  // * Show some error UI when any widget in the app fails to build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('An error occurred'),
      ),
      body: Center(child: Text(details.toString())),
    );
  };
}

Future<void> initFirebase() async {
  //TODO: investigate about a way to setup custom analytics events
  //TODO: investigate about the best way to setup Crashalytics
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
}
