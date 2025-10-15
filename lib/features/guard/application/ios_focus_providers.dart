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
  final isActive = ref.watch(guardStreamActiveProvider);
  if (!isActive) {
    yield const <String, dynamic>{};
    return;
  }
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
  final isActive = ref.watch(guardStreamActiveProvider);
  if (!isActive) {
    yield const <String>[];
    return;
  }
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

  // poll every second
  yield* Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final current = await getNativeLogs();
      return current;
    } catch (e) {
      focusLog('logsStreamProvider poll error', data: e);
      return last;
    }
  }).where((current) {
    final changed =
        current.length != last.length || current.join('\n') != last.join('\n');
    if (changed) last = current;
    return changed;
  });
});

/// Android snapshot provider - polls every 30s
final androidSnapshotProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  final isActive = ref.watch(guardStreamActiveProvider);
  if (!isActive) {
    yield const <String, dynamic>{};
    return;
  }
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
  final isActive = ref.watch(guardStreamActiveProvider);
  if (!isActive) {
    return const AsyncValue.data(<String, dynamic>{});
  }
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

final guardStreamActiveProvider =
    StateProvider.autoDispose<bool>((ref) => false);
