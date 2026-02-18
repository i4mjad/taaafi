import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StreakDisplayMode { days, detailed }

class StreakDisplayNotifier extends StateNotifier<StreakDisplayMode> {
  StreakDisplayNotifier() : super(StreakDisplayMode.days) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDetailed = prefs.getBool('detailed_streak_enabled') ?? false;
    state = isDetailed ? StreakDisplayMode.detailed : StreakDisplayMode.days;
  }

  Future<void> setDisplayMode(StreakDisplayMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'detailed_streak_enabled', mode == StreakDisplayMode.detailed);
  }
}

final streakDisplayProvider =
    StateNotifierProvider<StreakDisplayNotifier, StreakDisplayMode>((ref) {
  return StreakDisplayNotifier();
});

// This class handles the detailed streak calculation without frequent rebuilds
class DetailedStreakInfo {
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final DateTime lastUpdated;

  DetailedStreakInfo({
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.lastUpdated,
  });

  factory DetailedStreakInfo.fromDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    // Approximate months (30 days per month)
    final months = days ~/ 30;

    return DetailedStreakInfo(
      months: months,
      days: days % 30,
      hours: hours % 24,
      minutes: minutes % 60,
      seconds: seconds % 60,
      lastUpdated: DateTime.now(),
    );
  }

  // Check if this detailed info needs updating (only update every second)
  bool needsUpdate() {
    return DateTime.now().difference(lastUpdated).inSeconds >= 1;
  }
}

// Provider to compute detailed streak info
final detailedStreakInfoProvider =
    Provider.family<DetailedStreakInfo, Duration>((ref, duration) {
  return DetailedStreakInfo.fromDuration(duration);
});
