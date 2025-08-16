import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/guard_usage_repository.dart';
import '../../../core/logging/focus_log.dart';

/// iOS Screen Time auth status. On non-iOS, always true.
/// Note: Authorization status checking is handled during requestAuthorization flow
final iosAuthStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!Platform.isIOS) return true;
  // For now, assume authorization is needed and will be handled by requestAuthorization
  // TODO: Implement proper authorization status checking if needed
  return true;
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

  // Poll every 10 seconds for real-time feel and emit only when changed
  yield* Stream.periodic(const Duration(seconds: 10)).asyncMap((_) async {
    try {
      final snap = await iosGetSnapshot().timeout(
        const Duration(seconds: 3),
        onTimeout: () => lastSnapshot ?? <String, dynamic>{},
      );
      return snap;
    } catch (e) {
      focusLog('iosSnapshotProvider polling error', data: e);
      return lastSnapshot ?? <String, dynamic>{};
    }
  }).where((snap) {
    final changed =
        lastSnapshot == null || snap.toString() != lastSnapshot.toString();
    if (changed) lastSnapshot = snap;
    return changed;
  });
});

/// Manual refresh provider for immediate updates
final manualRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

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

  // Poll every 30 seconds for Android
  yield* Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
    try {
      return await androidGetSnapshot();
    } catch (e) {
      focusLog('androidSnapshotProvider polling error', data: e);
      return lastSnapshot ?? <String, dynamic>{};
    }
  }).where((snap) {
    final changed =
        lastSnapshot == null || snap.toString() != lastSnapshot.toString();
    if (changed) lastSnapshot = snap;
    return changed;
  });
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
