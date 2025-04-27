import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:riverpod_annotation/riverpod_annotation.dart'; // Re-add annotation import

part 'connectivity_provider.g.dart'; // Re-add part directive

/// Provides the singleton instance of [Connectivity].
@Riverpod(keepAlive: true)
Connectivity connectivity(ConnectivityRef ref) {
  return Connectivity();
}

/// Re-introduce the StreamProvider
@Riverpod(keepAlive: true)
Stream<bool> networkStatus(NetworkStatusRef ref) async* {
  final connectivity = ref.watch(connectivityProvider);

  // Initial check
  if (kDebugMode) {
    print('[NetworkStatusProvider] Running - Getting initial status...');
  }
  final initialStatus = await connectivity.checkConnectivity();
  // Log the actual initial status enum
  if (kDebugMode) {
    print('[NetworkStatusProvider] Initial check result raw: $initialStatus');
  }
  final isOnlineInitial = initialStatus != ConnectivityResult.none;
  if (kDebugMode) {
    print(
        '[NetworkStatusProvider] Initial status derived: ${isOnlineInitial ? 'Online' : 'Offline'}');
  }
  yield isOnlineInitial;

  // Listen to stream changes
  if (kDebugMode) {
    print('[NetworkStatusProvider] Listening for changes...');
  }
  await for (final status in connectivity.onConnectivityChanged) {
    // Log the actual changed status enum
    if (kDebugMode) {
      print('[NetworkStatusProvider] Stream change result raw: $status');
    }
    final isOnlineChange = status != ConnectivityResult.none;
    if (kDebugMode) {
      print(
          '[NetworkStatusProvider] Change detected derived: ${isOnlineChange ? 'Online' : 'Offline'}');
    }
    yield isOnlineChange;
  }
}
