import 'dart:async';

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
  //Initialize Notification settings
  await MessagingService.instance.init();

  //Setup error handeling pages
  registerErrorHandlers(container);

  runApp(UncontrolledProviderScope(
    container: container,
    child: MyApp(),
  ));
}

void registerErrorHandlers(ProviderContainer container) async {
  // * Show some error UI if any uncaught exception happens
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError;
    container
        .read(errorLoggerProvider)
        .logException(details.exception, details.stack);
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
              onPressed: () async {
                final deviceInfo = DeviceInfoPlugin();
                String deviceDetails = '';

                if (defaultTargetPlatform == TargetPlatform.android) {
                  final androidInfo = await deviceInfo.androidInfo;
                  deviceDetails =
                      'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})\n'
                      'Device: ${androidInfo.manufacturer} ${androidInfo.model}';
                } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                  final iosInfo = await deviceInfo.iosInfo;
                  deviceDetails = 'iOS ${iosInfo.systemVersion}\n'
                      'Device: ${iosInfo.name} ${iosInfo.model}';
                }

                String userInfo = 'Not logged in';
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  userInfo = 'User ID: ${currentUser.uid}\n'
                      'Email: ${currentUser.email ?? "No email"}\n'
                      'Display Name: ${currentUser.displayName ?? "No name"}';
                }

                final body = '''
                              Error Report

                              Device Information:
                              $deviceDetails

                              User Information:
                              $userInfo

                              Error Details:
                              ${details.exception}

                              Stack Trace:
                              ${details.stack}
                              ''';

                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'admin@ta3afi.app',
                  queryParameters: {
                    'subject': 'Error Report',
                    'body': body,
                  },
                );

                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                }
              },
              child: const Text('Report this error'),
            ),
          ],
        ),
      ),
    );
  };
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
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
}
