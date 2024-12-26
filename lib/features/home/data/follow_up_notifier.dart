import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/follow_up_service.dart';
import 'package:reboot_app_3/features/home/data/calendar_notifier.dart';
import 'package:reboot_app_3/features/home/data/statistics_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/follow_up_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_up_notifier.g.dart';

class UserStatistics {
  final int daysWithoutRelapse;
  final int totalDaysFromFirstDate;

  UserStatistics({
    required this.daysWithoutRelapse,
    required this.totalDaysFromFirstDate,
  });
}

@riverpod
@riverpod
class FollowUpNotifier extends _$FollowUpNotifier {
  late final FollowUpService _service;

  @override
  FutureOr<UserStatistics> build() async {
    _service = ref.read(followUpServiceProvider);
    final daysWithoutRelapse = await _service.calculateDaysWithoutRelapse();
    final totalDaysFromFirstDate =
        await _service.calculateTotalDaysFromFirstDate();

    return UserStatistics(
      daysWithoutRelapse: daysWithoutRelapse,
      totalDaysFromFirstDate: totalDaysFromFirstDate,
    );
  }

  Future<void> createFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await _service.createFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
      ref.read(streakNotifierProvider.notifier).refreshStreakStatistics();
      ref.read(statisticsNotifierProvider.notifier).refreshUserStatistics();
      ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
      ref.read(streakNotifierProvider.notifier).refreshStreakStatistics();
      ref.read(statisticsNotifierProvider.notifier).refreshUserStatistics();
      ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFollowUp(String followUpId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteFollowUp(followUpId: followUpId);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
      ref.read(streakNotifierProvider.notifier).refreshStreakStatistics();
      ref.read(statisticsNotifierProvider.notifier).refreshUserStatistics();
      ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAllFollowUps() async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteAllFollowUps();
      state = AsyncValue.data(await build());

      // Refresh other notifiers
      ref.read(streakNotifierProvider.notifier).refreshStreakStatistics();
      ref.read(statisticsNotifierProvider.notifier).refreshUserStatistics();
      ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createMultipleFollowUps(List<FollowUpModel> followUps) async {
    state = const AsyncValue.loading();
    try {
      await _service.createMultipleFollowUps(followUps: followUps);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
      ref.read(streakNotifierProvider.notifier).refreshStreakStatistics();
      ref.read(statisticsNotifierProvider.notifier).refreshUserStatistics();
      ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@Riverpod(keepAlive: true)
FollowUpService followUpService(FollowUpServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = FollowUpRepository(firestore);
  return FollowUpService(repository);
}
