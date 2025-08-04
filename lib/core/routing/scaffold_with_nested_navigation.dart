import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

class ScaffoldWithNestedNavigation extends ConsumerWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index, WidgetRef ref) {
    // Community tab index is 2 (home=0, vault=1, community=2, groups=3, account=4)
    const int communityTabIndex = 2;

    if (index == communityTabIndex) {
      // Refresh community status when community tab is clicked
      ref.read(communityScreenStateProvider.notifier).refresh();

      // Also invalidate the current profile provider to force fresh data
      ref.invalidate(currentCommunityProfileProvider);
    }

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
  Widget build(BuildContext context, WidgetRef ref) {
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
                  LucideIcons.user2,
                  size: 20,
                ),
              ),
            ],
            onDestinationSelected: (index) => _goBranch(index, ref),
          )),
    );
  }
}
