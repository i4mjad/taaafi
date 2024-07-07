import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/scaffold_with_nested_navigation.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/account/presentation/account_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/complete_account_registeration.dart';
import 'package:reboot_app_3/features/authentication/presentation/confirm_user_details_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/forgot_password_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/login_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/signup_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/legacy_document_provider.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/new_document_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home_screen.dart';
import 'package:reboot_app_3/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_routes.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  // Watch the auth state changes
  final authState = ref.watch(authStateChangesProvider);
  final userDocumentState = ref.watch(legacyDocumentNotifierProvider);
  final newUserDocumentState = ref.watch(newUserDocumentNotifierProvider);
  final userDocNotifier = ref.read(newUserDocumentNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,

    // debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isLoggedIn = authState.asData?.value != null;
      final legacyUserDocumentState = ref.watch(legacyDocumentNotifierProvider);
      final newUserDocumentState = ref.watch(newUserDocumentNotifierProvider);

      if (isLoggedIn) {
        // If legacyUserDocumentState is still loading, do nothing
        if (legacyUserDocumentState is AsyncLoading ||
            newUserDocumentState is AsyncLoading) {
          return null;
        }

        final legacyUserDocument = legacyUserDocumentState.value;
        final newUserDocument = newUserDocumentState.value;

        // If both legacyUserDocumentState and newUserDocumentState have errors or are null, redirect to complete account registration
        if ((legacyUserDocument == null && newUserDocument == null) ||
            (legacyUserDocumentState is AsyncError &&
                newUserDocumentState is AsyncError)) {
          return '/completeAccountRegisteration';
        }

        final legacyUserDocNotifier =
            ref.read(legacyDocumentNotifierProvider.notifier);
        final newUserDocNotifier =
            ref.read(newUserDocumentNotifierProvider.notifier);

        // Check for missing required data in the legacy document
        if (legacyUserDocument != null &&
            legacyUserDocNotifier.hasMissingData(legacyUserDocument)) {
          if (state.matchedLocation != '/completeAccountRegisteration') {
            return '/completeAccountRegisteration';
          }
          return null;
        }

        // Check for old document structure in the legacy document
        final hasOldStructure = await legacyUserDocNotifier.hasOldStructure();
        if (hasOldStructure) {
          if (state.matchedLocation != '/confirmProfileDetails') {
            return '/confirmProfileDetails';
          }
          return null;
        }

        // Redirect to home if the user is logged in and trying to access auth routes
        if (state.matchedLocation.startsWith('/onboarding')) {
          return '/home';
        }
      } else {
        // Non-logged-in user trying to access protected routes
        final isAuthRoute = state.matchedLocation.startsWith('/onboarding');
        if (!isAuthRoute && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
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
        routes: [
          GoRoute(
            path: 'login',
            name: RouteNames.login.name,
            builder: (context, state) => LogInScreen(),
            routes: [
              GoRoute(
                path: 'forgetPassword',
                name: RouteNames.forgotPassword.name,
                builder: (context, state) => ForgotPasswordScreen(),
              ),
              GoRoute(
                path: 'signup',
                name: RouteNames.signup.name,
                builder: (context, state) => SignUpScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/completeAccountRegisteration',
        name: RouteNames.completeAccountRegisteration.name,
        pageBuilder: (context, state) => NoTransitionPage(
          child: CompleteAccountRegisterationScreen(),
        ),
      ),
      GoRoute(
        path: '/confirmProfileDetails',
        name: RouteNames.confirmUserDetails.name,
        pageBuilder: (context, state) => NoTransitionPage(
          child: ConfirmUserDetailsScreen(),
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
                  //! Add Pages
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
                routes: [
                  //! Add Pages
                ],
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
                routes: [
                  //! Add Pages
                ],
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
                  child: AccountScreen(),
                ),
                routes: [
                  //! Add Pages
                ],
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
