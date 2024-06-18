import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/app_routes.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale locale) {
    var state = context.findAncestorStateOfType<_MyAppState>() as _MyAppState;
    state.setLocale(locale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _locale;

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
  }

  Future<void> localeCkeck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var _token = await Locale(prefs.getString("languageCode") as String, '');
    setState(() {
      _locale = _token;
    });
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(builder: (context, ref, child) {
        final goRouter = ref.watch(goRouterProvider);
        final theme = ref.watch(customThemeProvider);

        return CustomThemeInherited(
          customThemeData:
              currentTheme.darkTheme ? darkCustomTheme : lightCustomTheme,
          child: MaterialApp.router(
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
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            debugShowCheckedModeBanner: false,
            // onGenerateRoute: CustomRouter.allRoutes,
            // initialRoute: navbar,
            // home: HomeNavBar(),
            // navigatorObservers: [observer],
            routerConfig: goRouter,
            theme: theme.darkTheme == true ? darkTheme : lightTheme,
          ),
        );
      }),
    );
  }
}
