import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/app_routes.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/core/utils/firebase_remote_config_provider.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final theme = ref.watch(customThemeProvider);
    final locale = ref.watch(localeNotifierProvider);
    return AppTheme(
      customThemeData: theme.darkTheme ? darkCustomTheme : lightCustomTheme,
      child: MaterialApp.router(
        supportedLocales: [Locale('ar', ''), Locale('en', '')],
        locale: locale,
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
        routerConfig: goRouter,
        theme: theme.darkTheme == true ? darkTheme : lightTheme,
        builder: (context, child) {
          return ForceUpdateWidget(
            navigatorKey: rootNavigatorKey,
            forceUpdateClient: ForceUpdateClient(
              fetchRequiredVersion: () async {
                final remoteConfig =
                    await ref.read(firebaseRemoteConfigProvider.future);
                var string = remoteConfig.getString('required_version');

                return string;
              },
              iosAppStoreId: "1531562469",
            ),
            allowCancel: false,
            showForceUpdateAlert: (context, allowCancel) => showAlertDialog(
              context: context,
              title: AppLocalizations.of(context).translate('required-update'),
              content:
                  AppLocalizations.of(context).translate('required-update-p'),
              cancelActionText: allowCancel ? 'Later' : null,
              defaultActionText:
                  AppLocalizations.of(context).translate('update-now'),
            ),
            showStoreListing: (storeUrl) async {
              ref.read(urlLauncherProvider).launch(
                    storeUrl,
                    // * Open app store app directly (or fallback to browser)
                    mode: LaunchMode.externalApplication,
                  );
            },
            onException: (e, st) {
              // TODO: add this later
              // ref.read(errorLoggerProvider).logException(e, st);
            },
            child: child!,
          );
        },
      ),
    );
  }
}

/// Helper function for showing an adaptive alert dialog
Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? cancelActionText,
  required String defaultActionText,
  bool isDestructive = false,
  String? routeName,
}) {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelActionText != null)
            TextButton(
              child: Text(cancelActionText),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          TextButton(
            child: Text(defaultActionText),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
  return showCupertinoDialog(
    context: context,
    routeSettings: RouteSettings(name: routeName),
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (cancelActionText != null)
          CupertinoDialogAction(
            child: Text(cancelActionText),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(defaultActionText),
        ),
      ],
    ),
  );
}

// ignore_for_file:avoid-shadowing


