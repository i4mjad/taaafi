import 'dart:io';
import 'package:flutter/services.dart';
import '../../../core/logging/focus_log.dart';

const MethodChannel _chan = MethodChannel('analytics.usage');

Future<T?> _call<T>(String method, [dynamic args]) async {
  final t0 = DateTime.now();
  focusLog('🟢 [DART→NATIVE] $method: START', data: args != null ? {'args': args} : null);
  try {
    final res = await _chan.invokeMethod<T>(method, args);
    final duration = DateTime.now().difference(t0).inMilliseconds;
    focusLog(
        '🟢 [DART→NATIVE] $method: ✅ SUCCESS (${duration}ms)',
        data: res != null ? {'result': res} : null);
    return res;
  } catch (e, stackTrace) {
    final duration = DateTime.now().difference(t0).inMilliseconds;
    focusLog('🟢 [DART→NATIVE] $method: ❌ ERROR (${duration}ms)', 
        data: {'error': e.toString(), 'trace': stackTrace.toString().split('\n').take(3).join('\n')});
    rethrow;
  }
}

Future<bool> iosGetAuthorizationStatus() async {
  focusLog('=== iosGetAuthorizationStatus: START ===');
  if (!Platform.isIOS) {
    focusLog('iosGetAuthorizationStatus: not iOS, returning true');
    return true;
  }
  
  final status = await _call<bool>('ios_getAuthorizationStatus');
  final result = status ?? false;
  focusLog('iosGetAuthorizationStatus: final result = $result', data: {'status': status});
  focusLog('=== iosGetAuthorizationStatus: END ===');
  return result;
}

Future<void> iosRequestAuthorization() async {
  focusLog('=== iosRequestAuthorization: START ===');
  if (!Platform.isIOS) {
    focusLog('iosRequestAuthorization: not iOS, skipping');
    return;
  }
  
  await _call('ios_requestAuthorization');
  focusLog('=== iosRequestAuthorization: END ===');
}

Future<void> iosPresentPicker() async {
  focusLog('=== iosPresentPicker: START ===');
  if (!Platform.isIOS) {
    focusLog('iosPresentPicker: not iOS, skipping');
    return;
  }
  
  // Always check/request authorization before presenting picker
  focusLog('iosPresentPicker: checking authorization status...');
  final status = await iosGetAuthorizationStatus();
  focusLog('iosPresentPicker: authorization status = $status');
  
  if (!status) {
    focusLog('iosPresentPicker: ⚠️ authorization NOT granted, requesting...');
    await iosRequestAuthorization();
    
    // Verify authorization was granted
    focusLog('iosPresentPicker: re-checking authorization after request...');
    final newStatus = await iosGetAuthorizationStatus();
    focusLog('iosPresentPicker: new authorization status = $newStatus');
    
    if (!newStatus) {
      focusLog('iosPresentPicker: ❌ authorization DENIED, cannot show picker');
      throw Exception('Family Controls authorization is required to select apps');
    }
    focusLog('iosPresentPicker: ✅ authorization granted after request');
  } else {
    focusLog('iosPresentPicker: ✅ authorization already granted');
  }
  
  focusLog('iosPresentPicker: presenting picker...');
  await _call('ios_presentPicker');
  focusLog('=== iosPresentPicker: END ===');
}

Future<void> iosStartMonitoring() async {
  focusLog('=== iosStartMonitoring: START ===');
  if (!Platform.isIOS) {
    focusLog('iosStartMonitoring: not iOS, skipping');
    return;
  }
  
  await _call('ios_startMonitoring');
  focusLog('=== iosStartMonitoring: END ===');
}

Future<Map<String, dynamic>> iosGetSnapshot() async {
  if (!Platform.isIOS) return {};
  
  final map = await _call('ios_getSnapshot');
  final result = Map<String, dynamic>.from((map ?? {}) as Map);
  
  if (result.isEmpty) {
    focusLog('iosGetSnapshot: ⚠️ empty snapshot returned');
  } else {
    final apps = (result['apps'] as List?)?.length ?? 0;
    focusLog('iosGetSnapshot: ✅ snapshot received - apps=$apps');
  }
  
  return result;
}

Future<List<String>> getNativeLogs() async {
  if (Platform.isIOS) {
    final res = await _call<List<dynamic>>('ios_getLogs');
    final list =
        (res ?? const []).map((e) => e.toString()).toList(growable: false);
    return list.isEmpty ? readUiLogs() : list;
  } else if (Platform.isAndroid) {
    final res = await _call<List<dynamic>>('android_getLogs');
    final list =
        (res ?? const []).map((e) => e.toString()).toList(growable: false);
    return list.isEmpty ? readUiLogs() : list;
  }
  return readUiLogs();
}

Future<void> clearNativeLogs() async {
  if (Platform.isIOS) {
    await _call('ios_clearLogs');
  } else if (Platform.isAndroid) {
    await _call('android_clearLogs');
  }
  clearUiLogs();
}

/// One source of truth facade for permissions and setup
class FocusFacade {
  const FocusFacade();

  Future<void> requestPermissionsAndStartMonitoring() async {
    if (Platform.isIOS) {
      await iosRequestAuthorization();
      await iosStartMonitoring();
    } else if (Platform.isAndroid) {
      // On Android, open Usage Access settings screen for the user
      await _call('android_requestUsageAccess');
    }
  }
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
