import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/guard_usage_repository.dart';

/// iOS Screen Time auth status. On non-iOS, always true.
final iosAuthStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!Platform.isIOS) return true;
  return iosGetAuthorizationStatus();
});

/// Polls iosGetSnapshot every 60s and exposes the latest map.
/// On non-iOS, returns {}.
final iosSnapshotProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  if (!Platform.isIOS) {
    yield <String, dynamic>{};
    return;
  }

  // initial
  yield await iosGetSnapshot();

  final controller = StreamController<Map<String, dynamic>>();
  final timer = Timer.periodic(const Duration(seconds: 60), (_) async {
    try {
      final snap = await iosGetSnapshot();
      controller.add(snap);
    } catch (_) {
      // swallow errors for now
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  yield* controller.stream;
});
