import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'native_usage_bridge.g.dart';

/// Unified bridge for native usage data on iOS and Android.
///
/// Android: Uses `com.taaafi.fort` MethodChannel with category-level UsageStats.
/// iOS: Uses `com.taaafi.fort` MethodChannel with Screen Time API (FamilyControls).
class NativeUsageBridge {
  static const _channel = MethodChannel('com.taaafi.fort');

  static void _log(String message, [Object? data]) {
    final msg = data != null ? '[Fort Bridge] $message: $data' : '[Fort Bridge] $message';
    developer.log(msg, name: 'fort');
    // Also print so it shows in flutter run console
    // ignore: avoid_print
    print(msg);
  }

  /// Check if the app has permission to read usage data.
  Future<bool> checkUsagePermission() async {
    final method = Platform.isIOS ? 'ios_checkFamilyControlsAuth' : 'android_checkUsageAccess';
    _log('checkUsagePermission → calling $method');
    try {
      final result = await _channel.invokeMethod<bool>(method);
      _log('checkUsagePermission ← result', result);
      return result ?? false;
    } on PlatformException catch (e) {
      _log('checkUsagePermission ← ERROR', '${e.code}: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      _log('checkUsagePermission ← MISSING PLUGIN (channel not registered?)', e.message);
      return false;
    }
  }

  /// Request permission to read usage data.
  Future<bool> requestUsagePermission() async {
    final method = Platform.isIOS ? 'ios_requestFamilyControlsAuth' : 'android_requestUsageAccess';
    _log('requestUsagePermission → calling $method');
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<bool>(method);
        // Android opens settings — user must come back, so we re-check
        return checkUsagePermission();
      } else {
        final result = await _channel.invokeMethod<bool>(method);
        _log('requestUsagePermission ← result', result);
        return result ?? false;
      }
    } on PlatformException catch (e) {
      _log('requestUsagePermission ← ERROR', '${e.code}: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      _log('requestUsagePermission ← MISSING PLUGIN', e.message);
      return false;
    }
  }

  /// Get today's usage data from the native platform.
  Future<UsageSummary> getTodayUsage() async {
    _log('getTodayUsage → platform=${Platform.operatingSystem}');
    try {
      if (Platform.isAndroid) {
        return _getAndroidUsage();
      } else if (Platform.isIOS) {
        return _getIosUsage();
      }
      _log('getTodayUsage ← unsupported platform');
      return UsageSummary.empty(DateTime.now());
    } on PlatformException catch (e) {
      _log('getTodayUsage ← ERROR', '${e.code}: ${e.message}');
      return UsageSummary.empty(DateTime.now());
    } on MissingPluginException catch (e) {
      _log('getTodayUsage ← MISSING PLUGIN', e.message);
      return UsageSummary.empty(DateTime.now());
    }
  }

  Future<UsageSummary> _getAndroidUsage() async {
    _log('_getAndroidUsage → calling android_getCategoryUsage');
    final rawJson =
        await _channel.invokeMethod<String>('android_getCategoryUsage');
    _log('_getAndroidUsage ← rawJson length', rawJson?.length ?? 'null');
    if (rawJson == null) {
      _log('_getAndroidUsage ← null response, returning empty');
      return UsageSummary.empty(DateTime.now());
    }

    _log('_getAndroidUsage ← raw', rawJson);
    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    return UsageSummary.fromJson(data);
  }

  Future<UsageSummary> _getIosUsage() async {
    _log('_getIosUsage → calling ios_getUsageReport');
    try {
      final rawJson =
          await _channel.invokeMethod<String>('ios_getUsageReport');
      _log('_getIosUsage ← rawJson length', rawJson?.length ?? 'null');
      if (rawJson == null) {
        _log('_getIosUsage ← null response, returning empty');
        return UsageSummary.empty(DateTime.now());
      }

      _log('_getIosUsage ← raw', rawJson);
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final summary = UsageSummary.fromJson(data);
      _log('_getIosUsage ← parsed: categories=${summary.categories.length}, total=${summary.totalScreenTimeMinutes}min, pickups=${summary.pickups}');
      return summary;
    } on PlatformException catch (e) {
      _log('_getIosUsage ← ERROR', '${e.code}: ${e.message}');
      return UsageSummary.empty(DateTime.now());
    }
  }
}

@Riverpod(keepAlive: true)
NativeUsageBridge nativeUsageBridge(Ref ref) {
  return NativeUsageBridge();
}
