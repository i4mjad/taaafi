import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ios_focus_providers.dart';

class _IosLifecycleObserver extends WidgetsBindingObserver {
  _IosLifecycleObserver(this.ref);
  final Ref ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isIOS) return;
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(iosAuthStatusProvider);
    }
  }
}

/// Read this provider anywhere (e.g., in a page build) to register the observer.
final iosLifecycleProvider = Provider<void>((ref) {
  final obs = _IosLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(obs);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(obs));
});
