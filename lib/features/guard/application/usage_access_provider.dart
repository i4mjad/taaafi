import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsageAccessService {
  static const MethodChannel _channel = MethodChannel('analytics.usage');

  static Future<bool> checkAndroidUsageAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final bool result =
          await _channel.invokeMethod('android_checkUsageAccess');
      return result;
    } catch (e) {
      // If there's an error, assume permission is not granted
      return false;
    }
  }
}

final usageAccessGrantedProvider = AutoDisposeFutureProvider<bool>((ref) async {
  return await UsageAccessService.checkAndroidUsageAccess();
});
