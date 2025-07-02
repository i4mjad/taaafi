import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/app.dart';
import 'package:reboot_app_3/core/messaging/services/fcm_service.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/monitoring/mixpanel_analytics_client.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> runMainApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initalize Firebase
  await initFirebase();

  final container = ProviderContainer();
  // Track app opened event

  // * Preload MixpanelAnalyticsClient, so we can make unawaited analytics calls
  await container.read(mixpanelAnalyticsClientProvider.future);

  // * Set global container reference for FCM service
  MessagingService.setGlobalContainer(container);

  // * Initialize Notification settings
  await MessagingService.instance.init();

  //Setup error handeling pages
  registerErrorHandlers(container);

  runApp(
    ProviderScope(
      child: UncontrolledProviderScope(
        container: container,
        child: MyApp(),
      ),
    ),
  );
}

void registerErrorHandlers(ProviderContainer container) {
  // Handle uncaught Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (e, s) {
      debugPrint('Failed to record crash: $e\n$s');
    }

    try {
      container
          .read(errorLoggerProvider)
          .logException(details.exception, details.stack);
    } catch (e, s) {
      debugPrint('Failed to log exception: $e\n$s');
    }

    debugPrint(details.toString());
  };

  // Handle errors from the platform/OS
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint(error.toString());
    return true;
  };

  // Custom error UI when a widget fails to build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('An error occurred'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => sendErrorReport(details, container),
              child: const Text('Report this error'),
            ),
          ],
        ),
      ),
    );
  };
}

Future<void> sendErrorReport(
    FlutterErrorDetails details, ProviderContainer container) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final deviceInfo = DeviceInfoPlugin();

  String userInfo = currentUser != null
      ? 'User ID: ${currentUser.uid}\nEmail: ${currentUser.email ?? "No email"}\nDisplay Name: ${currentUser.displayName ?? "No name"}'
      : 'Not logged in';

  String deviceDetails = 'Unknown Device';
  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceDetails =
          'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})\n'
          'Device: ${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceDetails =
          'iOS ${iosInfo.systemVersion}\nDevice: ${iosInfo.name} ${iosInfo.model}';
    }
  } catch (e) {
    debugPrint('Failed to get device info: $e');
  }

  final body = '''
              Error Report

              Device Information:
              $deviceDetails

              User Information:
              $userInfo

              Error Details:
              ${details.exception.toString()}

              Stack Trace:
              ${details.stack.toString()}
              ''';

  final Uri emailLaunchUri = Uri.parse(
      'mailto:admin@ta3afi.app?subject=${Uri.encodeComponent("Error Report")}&body=${Uri.encodeComponent(body)}');

  if (await canLaunchUrl(emailLaunchUri)) {
    await container.read(urlLauncherProvider).launch(emailLaunchUri);
  } else {
    debugPrint(
        '[URL Launcher] No email app found or cannot launch mailto link.');
  }
}

Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FirebaseCrashlytics.instance
        .setUserIdentifier(FirebaseAuth.instance.currentUser?.uid ?? 'Unknown');
    // * Setup error handeling pages
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
}
