import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_simple.g.dart';

// ==================== PROVIDERS ====================

/// Provider for the startup security service
@Riverpod(keepAlive: true)
StartupSecurityService startupSecurityService(StartupSecurityServiceRef ref) {
  return StartupSecurityService();
}

// Enhanced app startup with security checks
@Riverpod(keepAlive: true)
Future<SecurityStartupResult> appStartupWithSecurity(
    AppStartupWithSecurityRef ref) async {
  ref.onDispose(() {
    ref.invalidate(userDocumentsNotifierProvider);
    ref.invalidate(userNotifierProvider);
    ref.invalidate(startupSecurityServiceProvider);
  });

  await Future.delayed(Duration(milliseconds: 1000));

  // Initialize core dependencies
  await ref.watch(sharedPreferencesProvider.future);
  await ref.read(userNotifierProvider.future);

  // Initialize security and check for device/user bans
  final securityService = ref.watch(startupSecurityServiceProvider);
  final securityResult = await securityService.initializeAppSecurity();

  return securityResult;
}

/// Widget class to manage asynchronous app initialization with security checks
class AppStartupWithSecurityWidget extends ConsumerWidget {
  const AppStartupWithSecurityWidget({super.key, required this.onLoaded});
  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupWithSecurityProvider);
    return appStartupState.when(
      data: (securityResult) {
        // Check if device or user is banned
        if (securityResult.isBlocked) {
          return AppBannedScreen(securityResult: securityResult);
        }

        // Log warning if security check failed but allow app to continue
        if (securityResult.hasWarning) {
          // Could show a toast/snackbar here if needed
          debugPrint('Security Warning: ${securityResult.message}');
        }

        return onLoaded(context);
      },
      loading: () => const AppStartupLoadingWidget(),
      error: (e, st) => AppStartupErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(appStartupWithSecurityProvider),
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
            CircularProgressIndicator(color: theme.primary[600]),
            verticalSpace(Spacing.points16),
            Text(
              'Initializing Security...',
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
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.error[600],
              ),
              verticalSpace(Spacing.points16),
              Text(
                'Initialization Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: theme.error[800],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              verticalSpace(Spacing.points8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
              verticalSpace(Spacing.points24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to show when device or user is banned (Simplified version)
class AppBannedScreen extends StatelessWidget {
  const AppBannedScreen({super.key, required this.securityResult});
  final SecurityStartupResult securityResult;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isDeviceBan =
        securityResult.status == SecurityStartupStatus.deviceBanned;

    return Scaffold(
      backgroundColor: theme.error[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.error[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeviceBan ? Icons.smartphone : Icons.person_off,
                  size: 64,
                  color: theme.error[600],
                ),
              ),

              verticalSpace(Spacing.points24),

              // Title
              Text(
                isDeviceBan ? 'Device Restricted' : 'Account Restricted',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: theme.error[800],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points16),

              // Message
              Text(
                securityResult.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.error[700],
                    ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points32),

              // Contact support information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.error[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.grey[600],
                          size: 20,
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: Text(
                            'If you believe this restriction was applied in error, please contact our support team for assistance.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: theme.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (securityResult.deviceId != null ||
                        securityResult.userId != null) ...[
                      verticalSpace(Spacing.points12),
                      Text(
                        'Reference ID: ${securityResult.deviceId ?? securityResult.userId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.grey[600],
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
