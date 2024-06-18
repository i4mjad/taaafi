// private navigators

import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/scaffold_with_nested_navigation.dart';
import 'package:reboot_app_3/features/account/presentation/account_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:reboot_app_3/presentation/screens/home/home_screen.dart';
import 'package:reboot_app_3/presentation/screens/ta3afi_liberary/widgets/content_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// the one and only GoRouter instance
part 'app_routes.g.dart';

@riverpod
GoRouter goRouter(ref) => GoRouter(
      initialLocation: '/home',
      navigatorKey: rootNavigatorKey,
      routes: [
        // Stateful nested navigation based on:
        // https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            // the UI shell
            return ScaffoldWithNestedNavigation(
                navigationShell: navigationShell);
          },
          branches: [
            // first tab (home)
            StatefulShellBranch(
              navigatorKey: shellNavigatorHomeKey,
              routes: [
                // top route inside branch
                GoRoute(
                  name: RouteNames.home.name,
                  path: '/home',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HomeScreen(),
                  ),
                  routes: [
                    // child route
                    GoRoute(
                      path: 'content',
                      name: RouteNames.content.name,
                      builder: (context, state) => ContentScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // second tab (vault)
            StatefulShellBranch(
              navigatorKey: shellNavigatorVaultKey,
              routes: [
                // top route inside branch
                GoRoute(
                  name: RouteNames.vault.name,
                  path: '/vault',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: VaultScreen(),
                  ),
                  routes: [
                    // child route
                    // GoRoute(
                    //   path: RouteNames.account.name,
                    //   builder: (context, state) => AccountScreen(),
                    // ),
                  ],
                ),
              ],
            ),
            // third tab (fellowship)
            StatefulShellBranch(
              navigatorKey: shellNavigatorFellowshipKey,
              routes: [
                // top route inside branch
                GoRoute(
                  name: RouteNames.fellowship.name,
                  path: '/fellowship',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: VaultScreen(),
                  ),
                  routes: [
                    // child route
                    // GoRoute(
                    //   path: RouteNames.account.name,
                    //   builder: (context, state) => AccountScreen(),
                    // ),
                  ],
                ),
              ],
            ),

            // forth tab (account)
            StatefulShellBranch(
              navigatorKey: shellNavigatorAccountKey,
              routes: [
                // top route inside branch
                GoRoute(
                  path: '/account',
                  name: RouteNames.account.name,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: UpdatedAccountScreen(),
                  ),
                  routes: [
                    // child route
                    // GoRoute(
                    //   path: 'details',
                    //   builder: (context, state) => const DetailsScreen(label: 'B'),
                    // ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
