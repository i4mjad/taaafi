import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/application/analytics_service.dart';
import 'package:reboot_app_3/features/vault/data/models/analytics_follow_up.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_notifier.g.dart';

@riverpod
PremiumAnalyticsService premiumAnalyticsService(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = FollowUpRepository(firestore, ref);
  return PremiumAnalyticsService(repository);
}

@riverpod
Future<List<AnalyticsFollowUp>> heatMapData(Ref ref) async {
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  if (!hasSubscription) {
    // Return fake heat map data for preview
    return _generateFakeHeatMapData();
  }

  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getHeatMapData();
}

@riverpod
Future<Map<String, double>> streakAverages(Ref ref) async {
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  if (!hasSubscription) {
    // Return fake streak averages for preview
    return _generateFakeStreakAverages();
  }

  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.calculateStreakAverages();
}

@riverpod
Future<Map<String, int>> triggerRadarData(Ref ref) async {
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  if (!hasSubscription) {
    // Return fake trigger data for preview
    return _generateFakeTriggerData();
  }

  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getTriggerRadarData();
}

@riverpod
Future<List<int>> riskClockData(Ref ref, [FollowUpType? filterType]) async {
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  if (!hasSubscription) {
    // Return fake risk clock data for preview
    return _generateFakeRiskClockData();
  }

  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getRiskClockData(filterType);
}

@riverpod
Future<MoodCorrelationData> moodCorrelationData(Ref ref) async {
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  if (!hasSubscription) {
    // Return fake mood correlation data for preview
    return _generateFakeMoodCorrelationData();
  }

  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getMoodCorrelationData();
}

// Add cached version that refreshes every 5 minutes
@Riverpod(keepAlive: true)
Future<MoodCorrelationData> cachedMoodCorrelationData(Ref ref) async {
  // Auto-refresh every 5 minutes
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  return ref.watch(moodCorrelationDataProvider.future);
}

// Fake data generators for preview
List<AnalyticsFollowUp> _generateFakeHeatMapData() {
  final random = Random();
  final List<AnalyticsFollowUp> fakeData = [];
  final now = DateTime.now();

  // Generate 90 days of fake data
  for (int i = 0; i < 90; i++) {
    final date = now.subtract(Duration(days: i));

    // 70% chance of clean day, 20% slip-up, 10% relapse
    final chance = random.nextDouble();
    FollowUpType type;

    if (chance < 0.7) {
      type = FollowUpType.none; // Clean day
    } else if (chance < 0.9) {
      type = FollowUpType.slipUp;
    } else {
      type = FollowUpType.relapse;
    }

    fakeData.add(AnalyticsFollowUp(
      id: 'fake_${i}',
      time: date,
      type: type,
      triggers: _getRandomTriggers(random),
      moodRating: random.nextInt(10) + 1, // 1-10 mood scale
    ));
  }

  return fakeData;
}

Map<String, double> _generateFakeStreakAverages() {
  return {
    '7days': 78.5, // 78.5% clean days in last 7 days
    '30days': 82.3, // 82.3% clean days in last 30 days
    '90days': 76.9, // 76.9% clean days in last 90 days
  };
}

Map<String, int> _generateFakeTriggerData() {
  return {
    'stress': 12,
    'boredom': 8,
    'loneliness': 6,
    'late-night': 10,
    'social-media': 9,
    'tiredness': 5,
    'anxiety': 7,
    'anger': 3,
  };
}

List<int> _generateFakeRiskClockData() {
  // Generate 24 hours of risk data (higher risk in evening/night)
  final List<int> hourlyRisk = [];
  for (int hour = 0; hour < 24; hour++) {
    int risk;
    if (hour >= 21 || hour <= 2) {
      // High risk during late night/early morning
      risk = Random().nextInt(8) + 5; // 5-12
    } else if (hour >= 18 && hour <= 20) {
      // Medium-high risk in evening
      risk = Random().nextInt(6) + 3; // 3-8
    } else if (hour >= 14 && hour <= 17) {
      // Medium risk afternoon
      risk = Random().nextInt(4) + 2; // 2-5
    } else {
      // Low risk morning/midday
      risk = Random().nextInt(3); // 0-2
    }
    hourlyRisk.add(risk);
  }
  return hourlyRisk;
}

MoodCorrelationData _generateFakeMoodCorrelationData() {
  return MoodCorrelationData(
    moodCounts: {
      1: 2, // Very low mood
      2: 5, // Low mood
      3: 8, // Below average
      4: 12, // Average
      5: 15, // Good
      6: 18, // Very good
      7: 12, // Great
      8: 8, // Excellent
      9: 4, // Amazing
      10: 2, // Perfect
    },
    relapseCounts: {
      1: 2, // More relapses when mood is very low
      2: 4, // High relapses in low mood
      3: 3, // Medium relapses
      4: 2, // Lower relapses
      5: 1, // Few relapses
      6: 1, // Very few relapses
      7: 0, // No relapses when mood is great
      8: 0, // No relapses
      9: 0, // No relapses
      10: 0, // No relapses when mood is perfect
    },
    correlation:
        -0.76, // Strong negative correlation (low mood = more relapses)
  );
}

List<String> _getRandomTriggers(Random random) {
  final allTriggers = [
    'stress',
    'boredom',
    'loneliness',
    'late-night',
    'social-media',
    'tiredness',
    'anxiety',
    'anger'
  ];

  // Randomly select 1-3 triggers
  final numTriggers = random.nextInt(3) + 1;
  allTriggers.shuffle(random);
  return allTriggers.take(numTriggers).toList();
}
