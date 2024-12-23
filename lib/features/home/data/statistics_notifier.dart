import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/statistics_service.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/statistics_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_notifier.g.dart';

class UserStatistics {
  final int daysWithoutRelapse;
  final int totalDaysFromFirstDate;
  final int longestRelapseStreak;

  UserStatistics({
    required this.daysWithoutRelapse,
    required this.totalDaysFromFirstDate,
    required this.longestRelapseStreak,
  });
}

@riverpod
class StatisticsNotifier extends _$StatisticsNotifier {
  late final StatisticsService _service;

  @override
  FutureOr<UserStatistics> build() async {
    _service = ref.read(statisticsServiceProvider);

    final daysWithoutRelapseFuture = _service.calculateDaysWithoutRelapse();
    final totalDaysFromFirstDateFuture =
        _service.calculateTotalDaysFromFirstDate();
    final longestRelapseStreakFuture = _service.calculateLongestRelapseStreak();

    final results = await Future.wait([
      daysWithoutRelapseFuture,
      totalDaysFromFirstDateFuture,
      longestRelapseStreakFuture,
    ]);

    return UserStatistics(
      daysWithoutRelapse: results[0],
      totalDaysFromFirstDate: results[1],
      longestRelapseStreak: results[2],
    );
  }

  Future<void> createFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await _service.createFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFollowUp(String followUpId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteFollowUp(followUpId: followUpId);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAllFollowUps() async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteAllFollowUps();
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@Riverpod(keepAlive: true)
StatisticsService statisticsService(StatisticsServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = StatisticsRepository(firestore);
  return StatisticsService(repository);
}
