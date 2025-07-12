import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'package:reboot_app_3/features/account/presentation/banned_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup.g.dart';

/// Provider for the startup security service
@Riverpod(keepAlive: true)
StartupSecurityService startupSecurityService(Ref ref) {
  return StartupSecurityService();
}

// https://codewithandrea.com/articles/robust-app-initialization-riverpod/
@Riverpod(keepAlive: true)
Future<SecurityStartupResult> appStartup(Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(userDocumentsNotifierProvider);
    ref.invalidate(userNotifierProvider);
    ref.invalidate(startupSecurityServiceProvider);
    ref.invalidate(localeNotifierProvider);
    // ref.invalidate(firebaseRemoteConfigProvider);
    // ref.invalidate(sharedPreferencesProvider);
    // ref.invalidate(onboardingRepositoryProvider);
  });

  // await Future.delayed(Duration(milliseconds: 500));

  //* await for all initialization code to be complete before returning
  await ref.watch(sharedPreferencesProvider.future);
  await ref.read(userNotifierProvider.future);

  // Initialize locale provider - this will load saved locale or default to Arabic
  ref.read(localeNotifierProvider);

  // Initialize security and check for device/user bans
  // NOTE: Device bans are checked FIRST (highest priority) before user bans
  final securityService = ref.watch(startupSecurityServiceProvider);
  final securityResult = await securityService.initializeAppSecurity();

  // Return security result - this will determine if app should load or show ban screen
  // Device bans take precedence over user bans in the security service
  return securityResult;

  // If user is logged in, ensure user document is loaded before proceeding
  // final currentUser = FirebaseAuth.instance.currentUser;
  // if (currentUser != null) {
  //   // Wait for user provider to be ready
  //   await ref.read(userNotifierProvider.future);

  //   // Wait for user document to be loaded (with timeout)
  //   try {
  //     await ref.read(userDocumentsNotifierProvider.future).timeout(
  //       Duration(seconds: 10), // 10 second timeout
  //       onTimeout: () {
  //         // If timeout, return null - this will be handled gracefully
  //         return null;
  //       },
  //     );
  //   } catch (e) {
  //     // If there's an error loading the document, continue anyway
  //     // The account status provider will handle the error state
  //   }
  // }

  // await ref.watch(mixpanelAnalyticsClientProvider.future);
  // await ref.watch(onboardingRepositoryProvider.future);
}

/// Widget class to manage asynchronous app initialization with security checks
class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({super.key, required this.onLoaded});
  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);
    return appStartupState.when(
      data: (securityResult) {
        // Check if device or user is banned
        // Device bans have highest priority and are checked first in the security service
        if (securityResult.isBlocked) {
          return AppBannedWidget(securityResult: securityResult);
        }

        // Show warning if security check failed but allow app to continue
        if (securityResult.hasWarning) {
          // Log warning but continue with app loading
          // You could also show a snackbar or toast here
        }

        return onLoaded(context);
      },
      loading: () => const AppStartupLoadingWidget(),
      error: (e, st) => AppStartupErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(appStartupProvider),
      ),
    );
  }
}

/// Widget to show while initialization is in progress
class AppStartupLoadingWidget extends StatelessWidget {
  const AppStartupLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: theme.primary[600]),
      ),
    );
  }
}

/// Widget to show if initialization fails
class AppStartupErrorWidget extends StatelessWidget {
  const AppStartupErrorWidget(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.headlineSmall),
            verticalSpace(Spacing.points16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
