import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

bool get focusLogEnabled {
  const env = bool.fromEnvironment('LOG_FOCUS', defaultValue: true);
  return env && kDebugMode;
}

String _sh(Object? o) {
  final s = o?.toString() ?? '';
  return s.length <= 300 ? s : '${s.substring(0, 300)}…';
}

void focusLog(String message, {Object? data}) {
  if (!focusLogEnabled) return;
  final m = data == null ? message : '$message — ${_sh(data)}';
  dev.log(m, name: 'Focus');
}
