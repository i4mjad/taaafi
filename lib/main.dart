import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';
import 'package:reboot_app_3/shared/services/notification_service.dart';
import 'package:reboot_app_3/shared/services/routing/custom_router.dart';
import 'package:reboot_app_3/shared/services/routing/routes_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  InitializationSettings initializationSettings = await setupNotifications();

  await setupFirebaseMesagging(initializationSettings);
  runApp(MyApp());
}

Future<void> setupFirebaseMesagging(
    InitializationSettings initializationSettings) async {
  RemoteMessage initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  await NotificationService.flutterLocalNotificationsPlugin.initialize(
      initializationSettings, onSelectNotification: (String payload) async {
    if (payload = null) {
      debugPrint('notification payload: ' + payload);
    }
    print(initialMessage);
  });
}

Future<InitializationSettings> setupNotifications() async {
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsiOS = IOSInitializationSettings(
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
    return MultiProvider(
      providers: [
        ListenableProvider<GoogleAuthenticationService>(
            create: (_) => GoogleAuthenticationService(FirebaseAuth.instance)),
        StreamProvider(
          create: (context) =>
              context.read<GoogleAuthenticationService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        supportedLocales: [Locale('ar', ''), Locale('en', '')],
        locale: _locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          // Check if the current device locale is supported
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
        navigatorObservers: [observer],
      ),
    );
  }
}
