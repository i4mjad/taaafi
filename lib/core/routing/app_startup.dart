import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup.g.dart';

// https://codewithandrea.com/articles/robust-app-initialization-riverpod/
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(userDocumentsNotifierProvider);
    ref.invalidate(userNotifierProvider);
    // ref.invalidate(firebaseRemoteConfigProvider);
    // ref.invalidate(sharedPreferencesProvider);
    // ref.invalidate(onboardingRepositoryProvider);
  });

  await Future.delayed(Duration(milliseconds: 1000));

  //* await for all initialization code to be complete before returning
  await ref.watch(sharedPreferencesProvider.future);
  await ref.read(userNotifierProvider.future);

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

/// Widget class to manage asynchronous app initialization
class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({super.key, required this.onLoaded});
  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);
    return appStartupState.when(
      data: (_) {
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
