import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:promize_sdk/promize_sdk.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/firebase_options.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:reboot_app_3/shared/Components/bottom_navbar.dart';
import 'package:reboot_app_3/shared/components/app-themes.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

import 'package:reboot_app_3/shared/services/notification_service.dart';
import 'package:reboot_app_3/shared/services/routing/custom_router.dart';
import 'package:reboot_app_3/shared/services/routing/routes_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool darkMode = false;
final _promizeSdk = PromizeSdk.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SetupContainer();

  InitializationSettings initializationSettings = await setupNotifications();
  await setupFirebaseMesagging(initializationSettings);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(MyApp());
}

Future<void> setupFirebaseMesagging(
    InitializationSettings initializationSettings) async {
  // RemoteMessage initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  await NotificationService.flutterLocalNotificationsPlugin
      .initialize(initializationSettings);
}

Future<InitializationSettings> setupNotifications() async {
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsiOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {});

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

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale locale) async {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>();

    state.setLocale(locale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  initState() {
    super.initState();
    localeCkeck();
    currentTheme.addListener(() {
      setState(() {});
    });
    _promizeSdk.initialize(
        apiKey:
            'oh51RjWT33x6nmejD677bYlBx7Cf9VdG2dgMx7t075Meu0arOYbluZgBcsfflyC2',
        siteId: '5liwmsi7su',
        baseUrl: 'https://ta3afi.live.promize.io');
  }

  Future<Null> localeCkeck() async {
    Locale _token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = await Locale(prefs.getString("languageCode"), '');
    if (_token != null) {
      setState(() {
        _locale = _token;
      }); //your home page is loaded
    } else {
      //replace it with the login page
      _locale = Locale("ar", "");
    }
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(builder: (context, ref, child) {
        final theme = ref.watch(customThemeProvider);

        return MaterialApp(
          supportedLocales: [Locale('ar', ''), Locale('en', '')],
          locale: _locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          debugShowCheckedModeBanner: false,
          onGenerateRoute: CustomRouter.allRoutes,
          initialRoute: navbar,
          home: HomeNavBar(),
          navigatorObservers: [observer],
          theme: theme.darkTheme == true ? darkTheme : lightTheme,
        );
      }),
    );
  }
}
