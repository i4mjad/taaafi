import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/scaffold_with_nested_navigation.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/account/presentation/account_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/login_screen.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:reboot_app_3/presentation/screens/home/home_screen.dart';
import 'package:reboot_app_3/presentation/screens/ta3afi_liberary/widgets/content_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_routes.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  // Watch the auth state changes
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;

      // Allow navigation to the login page without redirection
      if (!isLoggedIn &&
          state.matchedLocation != '/onboarding' &&
          state.matchedLocation != '/login') {
        return '/onboarding';
      }

      if (isLoggedIn && state.matchedLocation == '/onboarding') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding.name,
        pageBuilder: (context, state) => NoTransitionPage(
          child: OnBoardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login.name,
        pageBuilder: (context, state) => NoTransitionPage(
          child: LogInScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          child: ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                name: RouteNames.home.name,
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'content',
                    name: RouteNames.content.name,
                    builder: (context, state) => ContentScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorVaultKey,
            routes: [
              GoRoute(
                name: RouteNames.vault.name,
                path: '/vault',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: VaultScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorFellowshipKey,
            routes: [
              GoRoute(
                name: RouteNames.fellowship.name,
                path: '/fellowship',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: VaultScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorAccountKey,
            routes: [
              GoRoute(
                path: '/account',
                name: RouteNames.account.name,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: UpdatedAccountScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => NoTransitionPage(
      child: NotFoundScreen(),
    ),
  );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyPlaceholderWidget(
        message: '404 - Page not found!',
      ),
    );
  }
}

class EmptyPlaceholderWidget extends ConsumerWidget {
  const EmptyPlaceholderWidget({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            verticalSpace(Spacing.points16),
            PrimaryButton(
              onPressed: () {
                final isLoggedIn =
                    ref.watch(authRepositoryProvider).currentUser != null;
                context.goNamed(
                    isLoggedIn ? RouteNames.home.name : RouteNames.login.name);
              },
              text: 'Go Home',
            )
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.text, this.isLoading = false, this.onPressed});
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.white),
              ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
