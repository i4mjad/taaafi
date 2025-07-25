import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/models/analytics_follow_up.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';

class PremiumAnalyticsService {
  final FollowUpRepository _followUpRepository;

  PremiumAnalyticsService(this._followUpRepository);

  /// Get follow-ups for heat map calendar (last 12 months)
  Future<List<AnalyticsFollowUp>> getHeatMapData() async {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    // Get all follow-ups and filter by date
    final allFollowUps = await _followUpRepository.readAllFollowUps();
    final followUps = allFollowUps
        .where((f) =>
            f.time.isAfter(oneYearAgo) &&
            f.time.isBefore(now.add(const Duration(days: 1))))
        .toList();

    // Convert to analytics follow-ups
    return followUps.map((f) => AnalyticsFollowUp.fromFollowUp(f)).toList();
  }

  /// Calculate streak averages for 7, 30, and 90 days
  Future<Map<String, double>> calculateStreakAverages() async {
    final now = DateTime.now();
    final followUps = await _followUpRepository.readAllFollowUps();

    final averages = <String, double>{};

    // Calculate for each period
    for (final days in [7, 30, 90]) {
      final startDate = now.subtract(Duration(days: days));
      final periodFollowUps =
          followUps.where((f) => f.time.isAfter(startDate)).toList();

      // Count clean days (type == none)
      final cleanDays =
          periodFollowUps.where((f) => f.type == FollowUpType.none).length;
      averages['${days}days'] = cleanDays / days * 100;
    }

    return averages;
  }

  /// Get trigger analysis data (last 30 days)
  Future<Map<String, int>> getTriggerRadarData() async {
    // TODO: Implement real trigger data collection
    // For now, returning empty data until trigger collection is implemented
    // See: docs/future_trigger_implementation.md

    /* COMMENTED OUT - MOCK DATA
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get all follow-ups and filter by date
    final allFollowUps = await _followUpRepository.readAllFollowUps();
    final followUps = allFollowUps
        .where((f) =>
            f.time.isAfter(thirtyDaysAgo) &&
            f.time.isBefore(now.add(const Duration(days: 1))))
        .toList();

    // Filter only relapse events
    final relapses =
        followUps.where((f) => f.type != FollowUpType.none).toList();

    // Count triggers (using mock data for now)
    final triggerCounts = <String, int>{};
    for (final trigger in CommonTriggers.triggers) {
      // Mock: randomly assign some counts
      triggerCounts[trigger] =
          relapses.length > 0 ? (relapses.length * 0.2).round() : 0;
    }

    return triggerCounts;
    */

    return <String, int>{};
  }

  /// Get risk clock data (hourly distribution)
  Future<List<int>> getRiskClockData() async {
    final followUps = await _followUpRepository.readAllFollowUps();

    // Count relapses by hour
    final hourlyCounts = List<int>.filled(24, 0);

    for (final followUp in followUps) {
      if (followUp.type != FollowUpType.none) {
        hourlyCounts[followUp.time.hour]++;
      }
    }

    return hourlyCounts;
  }

  /// Get mood correlation data (last 30 days)
  Future<MoodCorrelationData> getMoodCorrelationData() async {
    // TODO: Implement real mood rating collection
    // For now, returning empty data until mood rating collection is implemented
    // See: docs/future_trigger_implementation.md

    /* COMMENTED OUT - MOCK DATA
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final allFollowUps = await _followUpRepository.readAllFollowUps();
    final followUps = allFollowUps
        .where((f) =>
            f.time.isAfter(thirtyDaysAgo) &&
            f.time.isBefore(now.add(const Duration(days: 1))))
        .toList();

    // Group by mood (using mock mood data for now)
    final moodGroups = <int, List<FollowUpModel>>{};
    for (int mood = -5; mood <= 5; mood++) {
      moodGroups[mood] = [];
    }

    // Mock: distribute follow-ups across moods
    for (final followUp in followUps) {
      final mockMood = (followUp.time.day % 11) - 5; // Mock mood based on day
      moodGroups[mockMood]?.add(followUp);
    }

    // Calculate correlation
    final moodCounts = <int, int>{};
    final relapseCounts = <int, int>{};

    for (int mood = -5; mood <= 5; mood++) {
      final followUpsForMood = moodGroups[mood] ?? [];
      moodCounts[mood] = followUpsForMood.length;

      final relapseCount = followUpsForMood
          .where((f) => f.type != FollowUpType.none)
          .length;
      relapseCounts[mood] = relapseCount;
    }

    // Calculate correlation coefficient (simplified)
    double correlation = 0.0;
    if (followUps.isNotEmpty) {
      // Simple correlation calculation
      correlation = -0.3; // Mock negative correlation
    }

          return MoodCorrelationData(
        moodCounts: moodCounts,
        relapseCounts: relapseCounts,
        correlation: correlation,
      );
    */

    return MoodCorrelationData(
      moodCounts: <int, int>{},
      relapseCounts: <int, int>{},
      correlation: 0.0,
    );
  }

  double _calculateCorrelation(
      Map<int, int> moodCounts, Map<int, int> relapseCounts) {
    // Simple correlation calculation
    // In production, use proper statistical correlation
    double totalMoodScore = 0;
    double totalRelapses = 0;
    int count = 0;

    moodCounts.forEach((mood, moodCount) {
      if (moodCount > 0) {
        totalMoodScore += mood * moodCount;
        totalRelapses += relapseCounts[mood] ?? 0;
        count += moodCount;
      }
    });

    if (count == 0) return 0;

    // Simplified correlation: negative moods correlate with more relapses
    final avgMood = totalMoodScore / count;
    final avgRelapse = totalRelapses / count;

    // Return a value between -1 and 1
    return avgMood < 0 && avgRelapse > 0.5 ? -0.6 : 0.2;
  }
}

class MoodCorrelationData {
  final Map<int, int> moodCounts;
  final Map<int, int> relapseCounts;
  final double correlation;

  MoodCorrelationData({
    required this.moodCounts,
    required this.relapseCounts,
    required this.correlation,
  });
}
