import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _chan = MethodChannel('analytics.usage');

Future<void> iosRequestAuthorization() async {
  if (!Platform.isIOS) return;
  await _chan.invokeMethod('ios_requestAuthorization');
}

Future<void> iosPresentPicker() async {
  if (!Platform.isIOS) return;
  await _chan.invokeMethod('ios_presentPicker');
}

Future<void> iosStartMonitoring() async {
  if (!Platform.isIOS) return;
  await _chan.invokeMethod('ios_startMonitoring');
}

Future<Map<String, dynamic>> iosGetSnapshot() async {
  if (!Platform.isIOS) return {};
  final map = await _chan.invokeMethod('ios_getSnapshot');
  return Map<String, dynamic>.from((map ?? {}) as Map);
}

Future<bool> iosGetAuthorizationStatus() async {
  if (!Platform.isIOS) return true;
  final res = await _chan.invokeMethod('ios_getAuthorizationStatus');
  return res == true;
}
