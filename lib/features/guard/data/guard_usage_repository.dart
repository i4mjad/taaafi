import 'dart:io';
import 'package:flutter/services.dart';
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

Future<void> iosRequestAuthorization() async {
  if (!Platform.isIOS) return;
  await _call('ios_requestAuthorization');
}

Future<void> iosPresentPicker() async {
  if (!Platform.isIOS) return;
  await _call('ios_presentPicker');
}

Future<void> iosStartMonitoring() async {
  if (!Platform.isIOS) return;
  await _call('ios_startMonitoring');
}

Future<Map<String, dynamic>> iosGetSnapshot() async {
  if (!Platform.isIOS) return {};
  final map = await _call('ios_getSnapshot');
  return Map<String, dynamic>.from((map ?? {}) as Map);
}

Future<Map<String, dynamic>> androidGetSnapshot() async {
  if (!Platform.isAndroid) return {};
  try {
    final map = await _call('android_getSnapshot');
    return Map<String, dynamic>.from((map ?? {}) as Map);
  } catch (e) {
    focusLog('androidGetSnapshot error', data: e);
    // Return mock data for development
    return {
      'apps': [],
      'pickups': 0,
      'notifications': 0,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
