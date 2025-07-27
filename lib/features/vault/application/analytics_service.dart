import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/analytics_follow_up.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/emotions/emotion_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/emotion_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class PremiumAnalyticsService {
  final FollowUpRepository _followUpRepository;
  late final EmotionRepository _emotionRepository;

  PremiumAnalyticsService(this._followUpRepository) {
    _emotionRepository =
        EmotionRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
  }

  /// Maps emotion names to mood ratings (-5 to +5 scale)
  static int _emotionToMoodRating(String emotionName) {
    // Very negative emotions (-5 to -4)
    const veryNegative = ['despair', 'dread', 'disgust'];

    // Negative emotions (-3 to -2)
    const negative = [
      'angry',
      'sad',
      'regret',
      'anxious',
      'fear',
      'frustration',
      'overwhelmed',
      'resentment',
      'disappointment',
      'exhaustion'
    ];

    // Slightly negative emotions (-1)
    const slightlyNegative = ['confusion', 'awkwardness'];

    // Slightly positive emotions (+1)
    const slightlyPositive = ['satisfaction', 'contentment', 'serenity'];

    // Positive emotions (+2 to +3)
    const positive = [
      'happy',
      'gratitude',
      'confidence',
      'compassion',
      'pride',
      'connection',
      'determination',
      'peace'
    ];

    // Very positive emotions (+4 to +5)
    const veryPositive = ['excitement', 'love', 'joy', 'inspiration'];

    if (veryNegative.contains(emotionName)) {
      return -5;
    } else if (negative.contains(emotionName)) {
      return negative.indexOf(emotionName) % 2 == 0 ? -3 : -2;
    } else if (slightlyNegative.contains(emotionName)) {
      return -1;
    } else if (slightlyPositive.contains(emotionName)) {
      return 1;
    } else if (positive.contains(emotionName)) {
      return positive.indexOf(emotionName) % 2 == 0 ? 2 : 3;
    } else if (veryPositive.contains(emotionName)) {
      return veryPositive.indexOf(emotionName) % 2 == 0 ? 4 : 5;
    }

    // Default neutral for unknown emotions
    return 0;
  }

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

    // Get all follow-ups once (performance optimization)
    final allFollowUps = await _followUpRepository.readAllFollowUps();
    final averages = <String, double>{};

    // Calculate for each period
    for (final days in [7, 30, 90]) {
      final startDate = now.subtract(Duration(days: days));

      // Filter follow-ups for this specific period
      final periodFollowUps = allFollowUps
          .where((f) =>
              f.time.isAfter(startDate) &&
              f.time.isBefore(now.add(Duration(days: 1))))
          .toList();

      // Group follow-ups by date
      final followUpsByDate = <DateTime, List<FollowUpModel>>{};
      for (final followUp in periodFollowUps) {
        final date = DateTime(
            followUp.time.year, followUp.time.month, followUp.time.day);
        followUpsByDate[date] = (followUpsByDate[date] ?? [])..add(followUp);
      }

      // Count clean days - days with no relapses (only free days or no follow-ups)
      int cleanDays = 0;
      for (int i = 0; i < days; i++) {
        final date =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayFollowUps = followUpsByDate[date] ?? [];

        // A day is clean if:
        // 1. No follow-ups at all, OR
        // 2. Only free-day follow-ups (type == none)
        final hasRelapseFollowUps =
            dayFollowUps.any((f) => f.type != FollowUpType.none);
        if (!hasRelapseFollowUps) {
          cleanDays++;
        }
      }

      averages['${days}days'] = (cleanDays / days * 100).roundToDouble();
    }

    return averages;
  }

  /// Get trigger analysis data (last 30 days)
  Future<Map<String, int>> getTriggerRadarData() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get all follow-ups and filter by date
      final allFollowUps = await _followUpRepository.readAllFollowUps();
      final recentFollowUps = allFollowUps
          .where((f) =>
              f.time.isAfter(thirtyDaysAgo) &&
              f.time.isBefore(now.add(const Duration(days: 1))))
          .toList();

      // Filter only relapse-related events (not free-day)
      final relapseFollowUps =
          recentFollowUps.where((f) => f.type != FollowUpType.none).toList();

      // Count triggers from all relapse follow-ups
      final triggerCounts = <String, int>{};

      for (final followUp in relapseFollowUps) {
        for (final trigger in followUp.triggers) {
          triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
        }
      }

      return triggerCounts;
    } catch (e) {
      // Return empty data if there's an error
      return <String, int>{};
    }
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
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Use batch queries instead of individual date queries - MUCH more efficient!
    final results = await Future.wait([
      _emotionRepository.readEmotionsByDateRange(thirtyDaysAgo, now),
      _followUpRepository.readFollowUpsByDateRange(thirtyDaysAgo, now),
    ]);

    final allEmotions = results[0] as List<EmotionModel>;
    final allFollowUps = results[1] as List<FollowUpModel>;

    // Group emotions by date for daily averages
    final dailyMoodData = <DateTime, List<int>>{};
    for (final emotion in allEmotions) {
      final dateKey =
          DateTime(emotion.date.year, emotion.date.month, emotion.date.day);
      final moodRating = _emotionToMoodRating(emotion.emotionName);
      dailyMoodData.putIfAbsent(dateKey, () => []).add(moodRating);
    }

    // Group follow-ups by date for relapse tracking
    final dailyRelapseData = <DateTime, bool>{};
    for (final followUp in allFollowUps) {
      final dateKey =
          DateTime(followUp.time.year, followUp.time.month, followUp.time.day);
      if (followUp.type != FollowUpType.none) {
        dailyRelapseData[dateKey] = true;
      }
    }

    // Calculate mood counts and relapse counts by mood level
    final moodCounts = <int, int>{};
    final relapseCounts = <int, int>{};

    // Initialize counts for all mood levels
    for (int mood = -5; mood <= 5; mood++) {
      moodCounts[mood] = 0;
      relapseCounts[mood] = 0;
    }

    // Process daily data more efficiently
    dailyMoodData.forEach((date, moodRatings) {
      // Calculate average mood for the day
      final avgMood =
          moodRatings.fold(0, (sum, mood) => sum + mood) / moodRatings.length;
      final roundedMood = avgMood.round().clamp(-5, 5);

      // Increment mood count
      moodCounts[roundedMood] = (moodCounts[roundedMood] ?? 0) + 1;

      // Check if there was a relapse on this day
      if (dailyRelapseData[date] == true) {
        relapseCounts[roundedMood] = (relapseCounts[roundedMood] ?? 0) + 1;
      }
    });

    // Calculate correlation coefficient
    final correlation = _calculateCorrelation(moodCounts, relapseCounts);

    return MoodCorrelationData(
      moodCounts: moodCounts,
      relapseCounts: relapseCounts,
      correlation: correlation,
    );
  }

  double _calculateCorrelation(
      Map<int, int> moodCounts, Map<int, int> relapseCounts) {
    // Calculate Pearson correlation coefficient between mood and relapse rate

    // Prepare data points (mood level, relapse rate for that mood)
    final List<double> moodValues = [];
    final List<double> relapseRates = [];

    for (int mood = -5; mood <= 5; mood++) {
      final totalDaysWithMood = moodCounts[mood] ?? 0;
      if (totalDaysWithMood > 0) {
        final relapses = relapseCounts[mood] ?? 0;
        final relapseRate = relapses / totalDaysWithMood;

        moodValues.add(mood.toDouble());
        relapseRates.add(relapseRate);
      }
    }

    if (moodValues.length < 2) return 0.0;

    // Calculate means
    final meanMood =
        moodValues.fold(0.0, (sum, val) => sum + val) / moodValues.length;
    final meanRelapseRate =
        relapseRates.fold(0.0, (sum, val) => sum + val) / relapseRates.length;

    // Calculate correlation coefficient
    double numerator = 0.0;
    double denomX = 0.0;
    double denomY = 0.0;

    for (int i = 0; i < moodValues.length; i++) {
      final diffMood = moodValues[i] - meanMood;
      final diffRelapse = relapseRates[i] - meanRelapseRate;

      numerator += diffMood * diffRelapse;
      denomX += diffMood * diffMood;
      denomY += diffRelapse * diffRelapse;
    }

    final denominator = math.sqrt(denomX * denomY);
    if (denominator == 0) return 0.0;

    final correlation = numerator / denominator;

    // Clamp to valid correlation range
    return correlation.clamp(-1.0, 1.0);
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
