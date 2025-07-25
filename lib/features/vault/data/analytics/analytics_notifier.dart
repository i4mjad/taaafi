import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/application/analytics_service.dart';
import 'package:reboot_app_3/features/vault/data/models/analytics_follow_up.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
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
  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getHeatMapData();
}

@riverpod
Future<Map<String, double>> streakAverages(Ref ref) async {
  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.calculateStreakAverages();
}

@riverpod
Future<Map<String, int>> triggerRadarData(Ref ref) async {
  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getTriggerRadarData();
}

@riverpod
Future<List<int>> riskClockData(Ref ref) async {
  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getRiskClockData();
}

@riverpod
Future<MoodCorrelationData> moodCorrelationData(Ref ref) async {
  final service = ref.read(premiumAnalyticsServiceProvider);
  return await service.getMoodCorrelationData();
}
