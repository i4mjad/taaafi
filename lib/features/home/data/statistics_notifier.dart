import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/statistics_service.dart';
import 'package:reboot_app_3/features/home/data/models/user_statistics.dart'
    as models;
import 'package:reboot_app_3/features/home/data/models/user_statistics.dart';
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

  factory UserStatistics.fromModel(models.UserStatisticsModel model) {
    return UserStatistics(
      daysWithoutRelapse: model.daysWithoutRelapse,
      totalDaysFromFirstDate: model.totalDaysFromFirstDate,
      longestRelapseStreak: model.longestRelapseStreak,
    );
  }
}

@riverpod
class StatisticsNotifier extends _$StatisticsNotifier {
  StatisticsService get service => ref.read(statisticsServiceProvider);

  @override
  FutureOr<UserStatistics> build() async {
    final daysWithoutRelapseFuture = service.calculateDaysWithoutRelapse();
    final totalDaysFromFirstDateFuture =
        service.calculateTotalDaysFromFirstDate();
    final longestRelapseStreakFuture = service.calculateLongestRelapseStreak();

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
      await service.createFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await service.updateFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFollowUp(String followUpId) async {
    state = const AsyncValue.loading();
    try {
      await service.deleteFollowUp(followUpId: followUpId);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAllFollowUps() async {
    state = const AsyncValue.loading();
    try {
      await service.deleteAllFollowUps();
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshUserStatistics() async {
    state = const AsyncValue.loading();
    try {
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

@riverpod
Stream<UserStatisticsModel> statisticsStream(StatisticsStreamRef ref) {
  final service = ref.read(statisticsServiceProvider);
  return service.userStatisticsStream();
}
