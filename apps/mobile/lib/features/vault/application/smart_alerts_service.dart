import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import 'package:reboot_app_3/features/vault/data/repositories/smart_alerts_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';

class SmartAlertsService {
  final FollowUpRepository _followUpRepository;
  final SmartAlertsRepository _smartAlertsRepository;
  final SubscriptionService _subscriptionService;

  SmartAlertsService(
    this._followUpRepository,
    this._smartAlertsRepository,
    this._subscriptionService,
  );

  /// Check user eligibility for smart alerts
  Future<SmartAlertEligibility> checkEligibility() async {
    // Must be Plus subscriber
    final hasSubscription = await _subscriptionService.isSubscriptionActive();
    if (!hasSubscription) {
      return const SmartAlertEligibility(
        isEligibleForRiskHour: false,
        isEligibleForVulnerability: false,
        riskHourReason: 'Plus subscription required',
        vulnerabilityReason: 'Plus subscription required',
        followUpCount: 0,
        weeksOfData: 0,
      );
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixWeeksAgo = now.subtract(const Duration(days: 42));

    // Get follow-ups for different time periods
    final last30DaysFollowUps =
        await _followUpRepository.readFollowUpsByDateRange(
      thirtyDaysAgo,
      now,
    );

    final last6WeeksFollowUps =
        await _followUpRepository.readFollowUpsByDateRange(
      sixWeeksAgo,
      now,
    );

    // Count total follow-ups (clean + relapse) in last 30 days
    final totalFollowUps = last30DaysFollowUps.length;

    // Calculate weeks of data
    final oldestFollowUp = await _getOldestFollowUp();
    final weeksOfData = oldestFollowUp != null
        ? (now.difference(oldestFollowUp.time).inDays / 7).floor()
        : 0;

    // Check eligibility for high-risk hour alert
    bool isEligibleForRiskHour = false;
    String? riskHourReason;

    if (totalFollowUps >= 30) {
      isEligibleForRiskHour = true;
    } else {
      riskHourReason = 'need-followups-for-risk-hour:$totalFollowUps';
    }

    // Check eligibility for streak vulnerability alert
    bool isEligibleForVulnerability = false;
    String? vulnerabilityReason;

    if (weeksOfData >= 6) {
      isEligibleForVulnerability = true;
    } else {
      vulnerabilityReason = 'need-weeks-for-vulnerability:$weeksOfData';
    }

    return SmartAlertEligibility(
      isEligibleForRiskHour: isEligibleForRiskHour,
      isEligibleForVulnerability: isEligibleForVulnerability,
      riskHourReason: riskHourReason,
      vulnerabilityReason: vulnerabilityReason,
      followUpCount: totalFollowUps,
      weeksOfData: weeksOfData,
    );
  }

  /// Calculate the highest risk hour from last 30 days of relapse data
  Future<int?> calculateRiskHour() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get relapse events from last 30 days
    final followUps = await _followUpRepository.readFollowUpsByDateRange(
      thirtyDaysAgo,
      now,
    );

    // Filter only relapse events (not clean days)
    final relapseEvents =
        followUps.where((f) => f.type != FollowUpType.none).toList();

    if (relapseEvents.isEmpty) return null;

    // Count relapses by hour
    final hourlyCounts = <int, int>{};
    for (final event in relapseEvents) {
      final hour = event.time.hour;
      hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
    }

    // Find hour with highest count
    int maxCount = 0;
    int? riskHour;

    for (int hour = 0; hour < 24; hour++) {
      final count = hourlyCounts[hour] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        riskHour = hour;
      } else if (count == maxCount && riskHour != null) {
        // Tie-breaker: choose earliest hour
        if (hour < riskHour) {
          riskHour = hour;
        }
      }
    }

    // Update settings with calculated risk hour
    if (riskHour != null) {
      await _smartAlertsRepository.updateRiskHour(riskHour);
    }

    return riskHour;
  }

  /// Calculate the most vulnerable weekday from last 90 days
  Future<int?> calculateVulnerableWeekday() async {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Get relapse events from last 90 days
    final followUps = await _followUpRepository.readFollowUpsByDateRange(
      ninetyDaysAgo,
      now,
    );

    // Filter only relapse events (not clean days)
    final relapseEvents =
        followUps.where((f) => f.type != FollowUpType.none).toList();

    if (relapseEvents.isEmpty) return null;

    // Count relapses by weekday (1-7: Monday-Sunday)
    final weekdayCounts = <int, int>{};
    for (final event in relapseEvents) {
      final weekday = event.time.weekday; // 1-7 (Monday-Sunday)
      weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
    }

    // Find weekday with highest count
    int maxCount = 0;
    int? vulnerableWeekday;

    for (int weekday = 1; weekday <= 7; weekday++) {
      final count = weekdayCounts[weekday] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        vulnerableWeekday = weekday;
      } else if (count == maxCount && vulnerableWeekday != null) {
        // Tie-breaker: choose earliest in week (Monday first)
        if (weekday < vulnerableWeekday) {
          vulnerableWeekday = weekday;
        }
      }
    }

    // Update settings with calculated vulnerable weekday
    if (vulnerableWeekday != null) {
      await _smartAlertsRepository.updateVulnerableWeekday(vulnerableWeekday);
    }

    return vulnerableWeekday;
  }

  /// Check if user relapsed before scheduled alert time today
  Future<bool> hasRelapsedBeforeAlert(DateTime scheduledTime) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todaysFollowUps = await _followUpRepository.readFollowUpsByDateRange(
      startOfDay,
      scheduledTime,
    );

    // Check if any follow-up before scheduled time is a relapse
    return todaysFollowUps.any((f) => f.type != FollowUpType.none);
  }

  /// Check if it's time to recalculate risk patterns (daily at 3 AM)
  bool shouldRecalculatePatterns() {
    final now = DateTime.now();
    final lastThreeAM = DateTime(now.year, now.month, now.day, 3);

    // If it's past 3 AM today, we should have calculated today
    // If it's before 3 AM, we should have calculated yesterday
    final targetCalculationTime = now.hour >= 3
        ? lastThreeAM
        : lastThreeAM.subtract(const Duration(days: 1));

    return now.isAfter(targetCalculationTime);
  }

  /// Get the scheduled alert time for high-risk hour (30 minutes before)
  DateTime? getNextRiskHourAlertTime(int riskHour) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate 30 minutes before risk hour
    final alertHour = riskHour == 0 ? 23 : riskHour - 1;
    final alertMinute = riskHour == 0 ? 30 : 30;

    var alertTime =
        DateTime(today.year, today.month, today.day, alertHour, alertMinute);

    // If the time has passed today, schedule for tomorrow
    if (alertTime.isBefore(now)) {
      alertTime = alertTime.add(const Duration(days: 1));
    }

    return alertTime;
  }

  /// Get the next vulnerability alert time (custom hour on vulnerable weekday)
  DateTime? getNextVulnerabilityAlertTime(
      int vulnerableWeekday, int alertHour) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find next occurrence of vulnerable weekday
    int daysUntilVulnerableDay = vulnerableWeekday - now.weekday;
    if (daysUntilVulnerableDay <= 0) {
      daysUntilVulnerableDay += 7; // Next week
    }

    // If it's the vulnerable weekday but past alert hour, schedule for next week
    if (daysUntilVulnerableDay == 0 && now.hour >= alertHour) {
      daysUntilVulnerableDay = 7;
    }

    final alertDate = today.add(Duration(days: daysUntilVulnerableDay));
    return DateTime(
        alertDate.year, alertDate.month, alertDate.day, alertHour, 0);
  }

  /// Get oldest follow-up for calculating data history
  Future<FollowUpModel?> _getOldestFollowUp() async {
    try {
      final allFollowUps = await _followUpRepository.readAllFollowUps();
      if (allFollowUps.isEmpty) return null;

      // Sort by time and get oldest
      allFollowUps.sort((a, b) => a.time.compareTo(b.time));
      return allFollowUps.first;
    } catch (e) {
      return null;
    }
  }

  /// Check if two alerts would conflict (within 2-hour window)
  bool wouldAlertsConflict(DateTime alert1, DateTime alert2) {
    return alert1.difference(alert2).abs().inHours < 2;
  }

  /// Format hour for display (12 AM, 1 AM, etc.)
  String formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  /// Format weekday for display
  String formatWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  /// Generate appropriate alert message based on type and context
  String generateAlertMessage(
    SmartAlertType type, {
    int? hour,
    int? weekday,
    bool hasRelapsedToday = false,
    bool hadCleanWeek = false,
  }) {
    switch (type) {
      case SmartAlertType.highRiskHour:
        if (hour == null) return '';
        return '🛡️ Heads-up! Your high-risk hour starts at ${formatHour(hour)}. Plan a healthy distraction now.';

      case SmartAlertType.streakVulnerability:
        if (weekday == null) return '';

        if (hasRelapsedToday) {
          return '💪 Today is your challenging day, but you can still recover. Check in with your support group.';
        } else if (hadCleanWeek) {
          return '🌟 You stayed strong last ${formatWeekday(weekday)}—repeat the formula today!';
        } else {
          return '☀️ Good morning! ${formatWeekday(weekday)}s are your toughest day. Plan an evening walk or check in with your group.';
        }
    }
  }
}
