import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
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
    final theme = AppTheme.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStatePropertyAll<TextStyle>(
              TextStyles.bottomNavigationBarLabel,
            ),
          ),
          child: NavigationBar(
            height: 58,
            surfaceTintColor: theme.primary[50],
            indicatorColor: theme.primary[50],
            indicatorShape: CircleBorder(),
            selectedIndex: navigationShell.currentIndex,
            backgroundColor: theme.backgroundColor,
            shadowColor: theme.primary[900],
            elevation: 4,
            destinations: [
              NavigationDestination(
                label: AppLocalizations.of(context).translate("home"),
                icon: Icon(
                  LucideIcons.home,
                  size: 20,
                ),
              ),
              NavigationDestination(
                label: AppLocalizations.of(context).translate("vault"),
                icon: Icon(
                  LucideIcons.bookLock,
                  size: 20,
                ),
              ),
              NavigationDestination(
                label: AppLocalizations.of(context).translate("community"),
                icon: Icon(
                  LucideIcons.users,
                  size: 20,
                ),
              ),
              NavigationDestination(
                label: AppLocalizations.of(context).translate("group"),
                icon: Icon(
                  LucideIcons.heartHandshake,
                  size: 20,
                ),
              ),
              NavigationDestination(
                label: AppLocalizations.of(context).translate("account"),
                icon: Icon(
                  LucideIcons.settings,
                  size: 20,
                ),
              ),
            ],
            onDestinationSelected: _goBranch,
          )),
    );
  }
}
