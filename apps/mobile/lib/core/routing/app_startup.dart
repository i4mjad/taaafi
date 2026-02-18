import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'package:reboot_app_3/features/account/presentation/banned_screen.dart';
import 'package:reboot_app_3/features/plus/application/revenue_cat_auth_sync_service.dart';
import 'package:reboot_app_3/features/authentication/application/user_subscription_sync_service.dart';
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
  });

  // 🚀 OPTIMIZATION: Run independent initializations in parallel
  // SharedPreferences and user provider can load simultaneously
  await Future.wait([
    ref.watch(sharedPreferencesProvider.future),
    ref.read(userNotifierProvider.future),
  ]);

  // Initialize locale provider (sync - fast)
  ref.read(localeNotifierProvider);

  // 🚀 OPTIMIZATION: Fire RevenueCat initialization in background (non-blocking)
  unawaited(_initializeRevenueCatSafe(ref));

  // CRITICAL: Security check must complete and NOT be parallelized
  // This ensures ban status is properly checked before app loads
  final securityService = ref.watch(startupSecurityServiceProvider);
  final securityResult = await securityService.initializeAppSecurity();

  // Only sync subscription if security check passed and user is not banned
  if (!securityResult.isBlocked) {
    // Defer subscription sync - don't await it
    unawaited(_initializeSubscriptionSyncSafe(ref));
  }

  return securityResult;
}

/// Safe RevenueCat initialization that won't throw
Future<void> _initializeRevenueCatSafe(Ref ref) async {
  try {
    await ref.read(initializeRevenueCatAuthSyncProvider.future);
  } catch (e) {
    debugPrint('RevenueCat initialization failed: $e');
  }
  }

/// Safe subscription sync that won't throw
Future<void> _initializeSubscriptionSyncSafe(Ref ref) async {
  try {
    await ref.read(initializeUserSubscriptionSyncProvider.future);
  } catch (e) {
    debugPrint('User subscription sync failed: $e');
  }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spinner(),
            verticalSpace(Spacing.points16),
            Text(
              AppLocalizations.of(context).translate('app-loading'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.grey[700],
                  ),
            ),
          ],
        ),
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
