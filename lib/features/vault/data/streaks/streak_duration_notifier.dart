import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/application/streak_service.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/streak_display_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

// Detailed streak info for efficient UI updating
class DetailedStreakNotifier
    extends StateNotifier<Map<String, DetailedStreakInfo>> {
  final StreakService _service;
  Timer? _timer;
  DateTime _lastUpdateTime = DateTime.now();

  DetailedStreakNotifier(this._service)
      : super({
          'relapse': DetailedStreakInfo(
              months: 0,
              days: 0,
              hours: 0,
              minutes: 0,
              seconds: 0,
              lastUpdated: DateTime.now()),
          'pornOnly': DetailedStreakInfo(
              months: 0,
              days: 0,
              hours: 0,
              minutes: 0,
              seconds: 0,
              lastUpdated: DateTime.now()),
          'mastOnly': DetailedStreakInfo(
              months: 0,
              days: 0,
              hours: 0,
              minutes: 0,
              seconds: 0,
              lastUpdated: DateTime.now()),
          'slipUp': DetailedStreakInfo(
              months: 0,
              days: 0,
              hours: 0,
              minutes: 0,
              seconds: 0,
              lastUpdated: DateTime.now()),
        }) {
    _initializeStreaks();
  }

  Future<void> _initializeStreaks() async {
    // Get initial durations
    final relapseDuration =
        await _calculateStreakDuration(FollowUpType.relapse);
    final pornOnlyDuration =
        await _calculateStreakDuration(FollowUpType.pornOnly);
    final mastOnlyDuration =
        await _calculateStreakDuration(FollowUpType.mastOnly);
    final slipUpDuration = await _calculateStreakDuration(FollowUpType.slipUp);

    // Update state with initial values
    state = {
      'relapse': DetailedStreakInfo.fromDuration(relapseDuration),
      'pornOnly': DetailedStreakInfo.fromDuration(pornOnlyDuration),
      'mastOnly': DetailedStreakInfo.fromDuration(mastOnlyDuration),
      'slipUp': DetailedStreakInfo.fromDuration(slipUpDuration),
    };

    // Start timer to update every second
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _lastUpdateTime = DateTime.now();

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      final secondsElapsed =
          DateTime.now().difference(_lastUpdateTime).inSeconds;
      if (secondsElapsed > 0) {
        _updateDetailedInfo(secondsElapsed);
      }
    });
  }

  void _updateDetailedInfo(int additionalSeconds) {
    final updatedState = Map<String, DetailedStreakInfo>.from(state);

    for (final key in state.keys) {
      final current = state[key]!;

      // Calculate new total seconds
      int totalSeconds = current.seconds + additionalSeconds;
      int minutes = current.minutes;
      int hours = current.hours;
      int days = current.days;
      int months = current.months;

      // Adjust values as needed
      if (totalSeconds >= 60) {
        minutes += totalSeconds ~/ 60;
        totalSeconds = totalSeconds % 60;
      }

      if (minutes >= 60) {
        hours += minutes ~/ 60;
        minutes = minutes % 60;
      }

      if (hours >= 24) {
        days += hours ~/ 24;
        hours = hours % 24;
      }

      if (days >= 30) {
        months += days ~/ 30;
        days = days % 30;
      }

      updatedState[key] = DetailedStreakInfo(
        months: months,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: totalSeconds,
        lastUpdated: DateTime.now(),
      );
    }

    state = updatedState;
    _lastUpdateTime = DateTime.now();
  }

  // Re-sync with actual durations to ensure accuracy (call periodically)
  Future<void> refreshDurations() async {
    final relapseDuration =
        await _calculateStreakDuration(FollowUpType.relapse);
    final pornOnlyDuration =
        await _calculateStreakDuration(FollowUpType.pornOnly);
    final mastOnlyDuration =
        await _calculateStreakDuration(FollowUpType.mastOnly);
    final slipUpDuration = await _calculateStreakDuration(FollowUpType.slipUp);

    state = {
      'relapse': DetailedStreakInfo.fromDuration(relapseDuration),
      'pornOnly': DetailedStreakInfo.fromDuration(pornOnlyDuration),
      'mastOnly': DetailedStreakInfo.fromDuration(mastOnlyDuration),
      'slipUp': DetailedStreakInfo.fromDuration(slipUpDuration),
    };

    _lastUpdateTime = DateTime.now();
  }

  Future<Duration> _calculateStreakDuration(FollowUpType type) async {
    DateTime? userFirstDate;
    try {
      userFirstDate = await _service.getUserFirstDate();
    } catch (_) {
      // User first date not ready yet; return zero duration
      return Duration.zero;
    }

    // Use appropriate methods based on follow-up type
    switch (type) {
      case FollowUpType.relapse:
        return await _calcDurationFromLastFollowUp(type, userFirstDate);
      case FollowUpType.pornOnly:
        return await _calcDurationFromLastFollowUp(type, userFirstDate);
      case FollowUpType.mastOnly:
        return await _calcDurationFromLastFollowUp(type, userFirstDate);
      case FollowUpType.slipUp:
        return await _calcDurationFromSlipUp(userFirstDate);
      default:
        return await _calcDurationFromLastFollowUp(type, userFirstDate);
    }
  }

  Future<Duration> _calcDurationFromLastFollowUp(
      FollowUpType type, DateTime userFirstDate) async {
    final now = DateTime.now().toUtc();
    final firstDate = userFirstDate.toUtc();

    // Get follow-ups for the specific type
    final followUps = await _service.getFollowUpsByType(type);

    // If no follow-ups, calculate from first date
    if (followUps.isEmpty) {
      return now.difference(firstDate);
    }

    // Sort follow-ups by time (most recent first)
    followUps.sort((a, b) => b.time.compareTo(a.time));
    final lastFollowUpDate = followUps.first.time.toUtc();

    // Calculate days since last follow-up
    return now.difference(lastFollowUpDate);
  }

  Future<Duration> _calcDurationFromSlipUp(DateTime userFirstDate) async {
    final now = DateTime.now().toUtc();
    final firstDate = userFirstDate.toUtc();

    // Get slip-up follow-ups
    final slipUpFollowUps =
        await _service.getFollowUpsByType(FollowUpType.slipUp);

    // If there are slip-up follow-ups, use the most recent one
    if (slipUpFollowUps.isNotEmpty) {
      slipUpFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastSlipUpDate = slipUpFollowUps.first.time.toUtc();
      return now.difference(lastSlipUpDate);
    }

    // If no slip-up follow-ups, check for relapse follow-ups
    final relapseFollowUps =
        await _service.getFollowUpsByType(FollowUpType.relapse);

    // If there are relapse follow-ups, use the most recent one
    if (relapseFollowUps.isNotEmpty) {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastRelapseDate = relapseFollowUps.first.time.toUtc();
      return now.difference(lastRelapseDate);
    }

    // If no follow-ups at all, calculate from first date
    return now.difference(firstDate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final detailedStreakProvider = StateNotifierProvider<DetailedStreakNotifier,
    Map<String, DetailedStreakInfo>>((ref) {
  final service = ref.watch(streakServiceProvider);
  return DetailedStreakNotifier(service);
});

// Provider to periodically refresh the detailed streak data
final detailedStreakRefresherProvider = Provider.autoDispose((ref) {
  final detailedStreakNotifier = ref.watch(detailedStreakProvider.notifier);

  // Set up a timer to refresh every minute
  Timer.periodic(Duration(minutes: 1), (_) {
    detailedStreakNotifier.refreshDurations();
  });

  ref.onDispose(() {});
});
