import 'package:shared_preferences/shared_preferences.dart';

const String kHasSeenUsageAccessIntro = 'kHasSeenUsageAccessIntro';
const String kUsageAccessGrantedAt = 'kUsageAccessGrantedAt';

/// Check if user has seen the usage access intro dialog
Future<bool> getHasSeenUsageAccessIntro() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kHasSeenUsageAccessIntro) ?? false;
}

/// Set that user has seen the usage access intro dialog
Future<void> setHasSeenUsageAccessIntro(bool seen) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kHasSeenUsageAccessIntro, seen);

  // QA Instrumentation - Log when intro is marked as seen
  print('📱 [QA] Usage Access Intro marked as seen: $seen');
}

/// Record the timestamp when permission was granted
Future<void> setUsageAccessGrantedAt(DateTime timestamp) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kUsageAccessGrantedAt, timestamp.millisecondsSinceEpoch);

  // QA Instrumentation - Log when permission granted timestamp is recorded
  print('📱 [QA] Usage Access granted timestamp recorded: $timestamp');
}

/// Get the timestamp when permission was granted (if any)
Future<DateTime?> getUsageAccessGrantedAt() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int? timestamp = prefs.getInt(kUsageAccessGrantedAt);
  return timestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
      : null;
}
