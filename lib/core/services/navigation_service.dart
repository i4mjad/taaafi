import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/app_routes.dart';

class NavigationService {
  final GoRouter router;

  NavigationService(this.router);

  void navigateToHome() {
    // Use router.pushReplacement to clear the stack and navigate
    router.pushReplacement('/home');
  }
}

final navigationServiceProvider = AutoDisposeProvider<NavigationService>((ref) {
  final router = ref.watch(goRouterProvider);
  return NavigationService(router);
});
