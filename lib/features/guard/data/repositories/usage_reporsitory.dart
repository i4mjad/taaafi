import 'dart:io';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/features/guard/data/models.dart';

final _chan = const MethodChannel('analytics.usage');
Future<Map<String, dynamic>> _invoke(String method) {
  return _chan.invokeMethod(method).then((v) => Map<String, dynamic>.from(v));
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
