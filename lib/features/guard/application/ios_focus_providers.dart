import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/guard_usage_repository.dart';
import '../../../core/logging/focus_log.dart';

const MethodChannel _chan = MethodChannel('analytics.usage');

Future<T?> _call<T>(String method, [dynamic args]) async {
  final t0 = DateTime.now();
  focusLog('Dart→Native $method', data: args);
  try {
    final res = await _chan.invokeMethod<T>(method, args);
    focusLog(
        'Native→Dart $method OK (${DateTime.now().difference(t0).inMilliseconds} ms)',
        data: res);
    return res;
  } catch (e) {
    focusLog('Native→Dart $method ERROR', data: e);
    rethrow;
  }
}

/// iOS Screen Time auth status. On non-iOS, always true.
/// Checks if Family Controls authorization has been approved.
/// Note: Not autoDispose to maintain cached status and reduce unnecessary checks
final iosAuthStatusProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isIOS) return true;
  
  try {
    focusLog('iosAuthStatusProvider: checking authorization status...');
    final status = await _call<bool>('ios_getAuthorizationStatus');
    focusLog('iosAuthStatusProvider: authorization status', data: status);
    
    // If authorization is granted, cache it
    if (status == true) {
      focusLog('iosAuthStatusProvider: ✅ Authorization GRANTED');
    } else {
      focusLog('iosAuthStatusProvider: ❌ Authorization NOT granted');
    }
    
    return status ?? false;
  } catch (e) {
    focusLog('iosAuthStatusProvider: error checking status', data: e);
    return false;
  }
});

/// Streams iosGetSnapshot every 10s for near real-time updates.
/// On non-iOS, returns {}.
final iosSnapshotProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  if (!Platform.isIOS) {
    yield <String, dynamic>{};
    return;
  }

  Map<String, dynamic>? lastSnapshot;

  // Initial load with timeout safeguard
  try {
    final initialSnap = await iosGetSnapshot().timeout(
      const Duration(seconds: 3),
      onTimeout: () => <String, dynamic>{},
    );
    lastSnapshot = initialSnap;
    // IMPORTANT: yield the first value so listeners receive it immediately
    yield initialSnap;
  } catch (e) {
    focusLog('iosSnapshotProvider initial load error', data: e);
    yield <String, dynamic>{};
  }

  // Poll every 10 seconds but only if guard is active
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    // Check if still active before fetching
    final isActive = ref.read(guardStreamActiveProvider);
    if (!isActive) continue;

    try {
      final snap = await iosGetSnapshot().timeout(
        const Duration(seconds: 3),
        onTimeout: () => lastSnapshot ?? <String, dynamic>{},
      );

      final changed =
          lastSnapshot == null || snap.toString() != lastSnapshot.toString();
      if (changed) {
        lastSnapshot = snap;
        yield snap;
      }
    } catch (e) {
      focusLog('iosSnapshotProvider polling error', data: e);
    }
  }
});

/// Manual refresh provider for immediate updates
final manualRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Native logs provider
final nativeLogsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  // Refetch when manually refreshed
  ref.watch(manualRefreshProvider);
  // tiny delay to allow latest writes flush
  await Future<void>.delayed(const Duration(milliseconds: 50));
  try {
    return await getNativeLogs();
  } catch (e) {
    focusLog('nativeLogsProvider error', data: e);
    return const [];
  }
});

/// Streaming logs provider (polls periodically and emits only on change)
final logsStreamProvider =
    StreamProvider.autoDispose<List<String>>((ref) async* {
  // Also respond to manual refresh trigger
  ref.watch(manualRefreshProvider);

  List<String> last = const [];

  // initial fetch
  try {
    final initial = await getNativeLogs();
    last = initial;
    yield initial;
  } catch (e) {
    focusLog('logsStreamProvider initial error', data: e);
    yield const <String>[];
  }

  // poll every second but only if guard is active
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    // Check if still active before fetching
    final isActive = ref.read(guardStreamActiveProvider);
    if (!isActive) continue;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final current = await getNativeLogs();

      final changed = current.length != last.length ||
          current.join('\n') != last.join('\n');
      if (changed) {
        last = current;
        yield current;
      }
    } catch (e) {
      focusLog('logsStreamProvider poll error', data: e);
    }
  }
});

/// Android snapshot provider - polls every 30s
final androidSnapshotProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  if (!Platform.isAndroid) {
    yield <String, dynamic>{};
    return;
  }

  Map<String, dynamic>? lastSnapshot;

  // Initial load
  try {
    final initialSnap = await androidGetSnapshot();
    lastSnapshot = initialSnap;
    yield initialSnap;
  } catch (e) {
    focusLog('androidSnapshotProvider initial load error', data: e);
    yield <String, dynamic>{};
  }

  // Poll every 30 seconds for Android but only if guard is active
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    // Check if still active before fetching
    final isActive = ref.read(guardStreamActiveProvider);
    if (!isActive) continue;

    try {
      final snap = await androidGetSnapshot();

      final changed =
          lastSnapshot == null || snap.toString() != lastSnapshot.toString();
      if (changed) {
        lastSnapshot = snap;
        yield snap;
      }
    } catch (e) {
      focusLog('androidSnapshotProvider polling error', data: e);
    }
  }
});

/// Real-time snapshot that responds to manual refresh
final realtimeSnapshotProvider =
    Provider.autoDispose<AsyncValue<Map<String, dynamic>>>((ref) {
  // Watch manual refresh trigger to force re-fetch
  ref.watch(manualRefreshProvider);

  // Return appropriate provider based on platform
  if (Platform.isIOS) {
    return ref.watch(iosSnapshotProvider);
  } else if (Platform.isAndroid) {
    return ref.watch(androidSnapshotProvider);
  } else {
    return const AsyncValue.data(<String, dynamic>{});
  }
});

/// Provider to control when guard streams should be active
/// Not autoDisposed to maintain state across navigation
final guardStreamActiveProvider = StateProvider<bool>((ref) => false);
