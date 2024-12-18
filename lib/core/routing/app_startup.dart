import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/utils/firebase_remote_config_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:starter_architecture_flutter_firebase/src/constants/app_sizes.dart';
// import 'package:starter_architecture_flutter_firebase/src/features/onboarding/data/onboarding_repository.dart';
// import 'package:starter_architecture_flutter_firebase/src/utils/shared_preferences_provider.dart';

part 'app_startup.g.dart';

// https://codewithandrea.com/articles/robust-app-initialization-riverpod/
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  ref.onDispose(() {
    // TODO: ensure dependent providers are disposed as well
    ref.invalidate(firebaseRemoteConfigProvider);
    // ref.invalidate(sharedPreferencesProvider);
    // ref.invalidate(onboardingRepositoryProvider);
  });
  // TODO: Uncomment this to test that URL-based navigation and deep linking works
  //       even when there's a delay in the app startup logic
  await Future.delayed(Duration(seconds: 1));
  // await for all initialization code to be complete before returning
  // await ref.watch(sharedPreferencesProvider.future);
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
      data: (_) => onLoaded(context),
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
