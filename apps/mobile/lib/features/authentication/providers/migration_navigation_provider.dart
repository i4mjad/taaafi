import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';

part 'migration_navigation_provider.g.dart';

@riverpod
class MigrationNavigationNotifier extends _$MigrationNavigationNotifier {
  @override
  bool build() => false;

  void navigateToHome() {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      // Force a rebuild of the navigation stack
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(context).pushReplacement('/home');
      });
    }
  }
}
