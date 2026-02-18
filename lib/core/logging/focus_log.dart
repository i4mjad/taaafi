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
  _appendUiLog(m);
}

// Simple in-memory UI log buffer (fallback when native logs are unavailable)
const int _uiLogMax = 200;
final List<String> _uiLogs = <String>[];

void _appendUiLog(String line) {
  _uiLogs.add(line);
  if (_uiLogs.length > _uiLogMax) {
    _uiLogs.removeRange(0, _uiLogs.length - _uiLogMax);
  }
}

List<String> readUiLogs() => List<String>.unmodifiable(_uiLogs);

void clearUiLogs() => _uiLogs.clear();
