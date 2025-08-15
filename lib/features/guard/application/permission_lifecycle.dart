import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/guard/application/usage_access_provider.dart';

/// Observer that listens to app lifecycle changes and refreshes permissions on resume
class PermissionLifecycleObserver extends WidgetsBindingObserver {
  final ProviderRef ref;

  PermissionLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // QA Instrumentation - Log lifecycle changes
    print('📱 [QA] App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      // When app resumes (e.g., from Settings), re-check permissions
      print('📱 [QA] App resumed - refreshing usage access permission');
      ref.invalidate(usageAccessGrantedProvider);
    }
  }
}

/// Provider that manages the lifecycle observer
final permissionLifecycleProvider =
    Provider<PermissionLifecycleObserver>((ref) {
  final observer = PermissionLifecycleObserver(ref);

  // Register the observer
  WidgetsBinding.instance.addObserver(observer);

  // Clean up when provider is disposed
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    print('📱 [QA] Permission lifecycle observer disposed');
  });

  return observer;
});
