import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/app.dart';
import 'package:reboot_app_3/core/messaging/services/fcm_service.dart';
import 'package:reboot_app_3/core/monitoring/mixpanel_analytics_client.dart';
import 'package:reboot_app_3/firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> runMainApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initalize Firebase
  await initFirebase();

  final container = ProviderContainer();
  // Track app opened event

  // * Preload MixpanelAnalyticsClient, so we can make unawaited analytics calls
  await container.read(mixpanelAnalyticsClientProvider.future);

  //Initialize Notification settings
  await MessagingService.instance.init();

  //Setup error handeling pages
  registerErrorHandlers();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://8b5f32f9c6b6e9844338848ad1eadafa@o4507702647848960.ingest.de.sentry.io/4507702652108880';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    )),
  );
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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
}
