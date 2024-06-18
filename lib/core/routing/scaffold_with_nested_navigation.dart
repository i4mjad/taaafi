// private navigators

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

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
