import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/app_routes.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/core/theming/color_theme_provider.dart';
import 'package:reboot_app_3/core/utils/firebase_remote_config_provider.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reboot_app_3/core/messaging/services/fcm_service.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    final themeController = ref.watch(customThemeProvider);
    final colorTheme = ref.watch(colorThemeProvider);

    return AppTheme(
      customThemeData: themeController.darkTheme
          ? darkCustomTheme
          : getLightCustomTheme(colorTheme),
      child: startup.when(
        loading: () {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeController.darkTheme
                ? darkTheme
                : getLightTheme(colorTheme),
            home: const AppStartupLoadingWidget(),
          );
        },
        error: (e, st) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeController.darkTheme
                ? darkTheme
                : getLightTheme(colorTheme),
            home: AppStartupErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(appStartupProvider),
            ),
          );
        },
        data: (_) {
          final goRouter = ref.watch(goRouterProvider);
          final locale = ref.watch(localeNotifierProvider);

          // Initialize MessagingService with router
          MessagingService.initializeWithRouter(goRouter);

          return MaterialApp.router(
            routerConfig: goRouter,
            supportedLocales: const [Locale('ar', ''), Locale('en', '')],
            locale: locale,
            localizationsDelegates: const [
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
            theme: themeController.darkTheme
                ? darkTheme
                : getLightTheme(colorTheme),
            builder: (_, child) {
              // Startup is already complete, just wrap in ForceUpdateWidget
              return ForceUpdateWidget(
                navigatorKey: rootNavigatorKey,
                allowCancel: false,
                showForceUpdateAlert: (context, allowCancel) => showAlertDialog(
                  context: context,
                  title:
                      AppLocalizations.of(context).translate("required-update"),
                  content: AppLocalizations.of(context)
                      .translate("required-update-p"),
                  cancelActionText: allowCancel
                      ? AppLocalizations.of(context).translate("later")
                      : null,
                  defaultActionText:
                      AppLocalizations.of(context).translate("update-now"),
                ),
                showStoreListing: (uri) async {
                  ref.read(urlLauncherProvider).launch(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                },
                forceUpdateClient: ForceUpdateClient(
                  fetchRequiredVersion: () async {
                    final remoteConfig =
                        await ref.read(firebaseRemoteConfigProvider.future);
                    return remoteConfig.getString('required_version');
                  },
                  iosAppStoreId: "1531562469",
                ),
                child: child!,
              );
            },
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
  CustomThemeData? theme,
}) {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: routeName),
      builder: (context) => AlertDialog(
        title: Text(title,
            style:
                TextStyles.h6.copyWith(color: theme?.primary[600], height: 2)),
        content: Text(content, style: TextStyles.footnote.copyWith(height: 2)),
        actions: [
          if (cancelActionText != null)
            TextButton(
              child: Text(
                cancelActionText,
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          TextButton(
            child: Text(defaultActionText, style: TextStyles.small),
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
      title: Text(title,
          style:
              TextStyles.h6.copyWith(color: theme?.primary[600], height: 1.5)),
      content: Text(content, style: TextStyles.footnote.copyWith(height: 1.4)),
      actions: [
        if (cancelActionText != null)
          CupertinoDialogAction(
            child: Text(cancelActionText, style: TextStyles.small),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(defaultActionText,
              style: TextStyles.small.copyWith(color: theme?.primary[600])),
        ),
      ],
    ),
  );
}

// ignore_for_file:avoid-shadowing


