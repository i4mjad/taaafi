import 'dart:io';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/features/guard/data/models.dart';
import 'dart:convert';

final _chan = const MethodChannel('analytics.usage');

Future<Map<String, dynamic>> _invoke(String method) async {
  final raw = await _chan.invokeMethod(method);
  return raw is String ? jsonDecode(raw) : Map<String, dynamic>.from(raw);
}

Future<UsageSnapshot> loadSnapshot() async {
  final map =
      await _invoke(Platform.isIOS ? 'ios_getSnapshot' : 'android_getSnapshot');
  final apps = (map['apps'] as List)
      .map((m) => AppUsage(m['pkg'] ?? m['bundle'] ?? '',
          m['label'] ?? m['pkg'] ?? '', (m['minutes'] as num).toInt()))
      .toList();
  return UsageSnapshot(
      apps: apps,
      pickups: (map['pickups'] ?? 0) as int,
      notifications: (map['notifications'] as int?),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(((map['generatedAt'] ??
                  (DateTime.now().millisecondsSinceEpoch / 1000)) as num)
              .toInt() *
          1000));
}

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
  return Map<String, dynamic>.from(map ?? {});
}
