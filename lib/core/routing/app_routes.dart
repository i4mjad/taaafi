// private navigators
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/presentation/account_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:reboot_app_3/presentation/screens/account/account_screen.dart';
import 'package:reboot_app_3/presentation/screens/home/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeShell');
final _shellNavigatorVaultKey =
    GlobalKey<NavigatorState>(debugLabel: 'vaultShell');
final _shellNavigatorFellowshipKey =
    GlobalKey<NavigatorState>(debugLabel: 'fellowshipShell');
final _shellNavigatorAccountKey =
    GlobalKey<NavigatorState>(debugLabel: 'accountShell');

// the one and only GoRouter instance
final goRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // Stateful nested navigation based on:
    // https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // the UI shell
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        // first tab (home)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            // top route inside branch
            GoRoute(
              name: RouteNames.home.name,
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UpdatedHomeScreen(),
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

        // second tab (vault)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorVaultKey,
          routes: [
            // top route inside branch
            GoRoute(
              name: RouteNames.vault.name,
              path: '/vault',
              pageBuilder: (context, state) => const NoTransitionPage(
                //TODO: change this to the vault screen when it's created
                //! CHANGE THIS
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
          navigatorKey: _shellNavigatorFellowshipKey,
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
          navigatorKey: _shellNavigatorAccountKey,
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

// Stateful nested navigation based on:
// https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle:
              WidgetStatePropertyAll<TextStyle>(TextStyles.footnoteSelected),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          destinations: [
            NavigationDestination(
              label: AppLocalizations.of(context).translate("home"),
              icon: Icon(LucideIcons.home),
            ),
            NavigationDestination(
              label: AppLocalizations.of(context).translate("vault"),
              icon: Icon(LucideIcons.bookLock),
            ),
            NavigationDestination(
              label: AppLocalizations.of(context).translate("fellowship"),
              icon: Icon(LucideIcons.users),
            ),
            NavigationDestination(
              label: AppLocalizations.of(context).translate("account"),
              icon: Icon(LucideIcons.settings),
            ),
          ],
          onDestinationSelected: _goBranch,
        ),
      ),
    );
  }
}
