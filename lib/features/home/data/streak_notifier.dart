import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/streak_service.dart';
import 'package:reboot_app_3/features/home/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/home/data/repos/streak_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'streak_notifier.g.dart';

@riverpod
class StreakNotifier extends _$StreakNotifier {
  late final StreakService _service;

  @override
  FutureOr<StreakStatistics> build() async {
    _service = ref.read(streakServiceProvider);

    final userFirstDateFuture = _service.getUserFirstDate();
    final relapseStreakFuture = _service.calculateRelapseStreak();
    final pornOnlyStreakFuture = _service.calculatePornOnlyStreak();
    final mastOnlyStreakFuture = _service.calculateMastOnlyStreak();
    final slipUpStreakFuture = _service.calculateSlipUpStreak();

    final results = await Future.wait([
      userFirstDateFuture,
      relapseStreakFuture,
      pornOnlyStreakFuture,
      mastOnlyStreakFuture,
      slipUpStreakFuture,
    ]);

    return StreakStatistics(
      userFirstDate: results[0] as DateTime,
      relapseStreak: results[1] as int,
      pornOnlyStreak: results[2] as int,
      mastOnlyStreak: results[3] as int,
      slipUpStreak: results[4] as int,
    );
  }

  Future<void> refreshStreakStatistics() async {
    state = const AsyncValue.loading();
    final userFirstDateFuture = _service.getUserFirstDate();
    final relapseStreakFuture = _service.calculateRelapseStreak();
    final pornOnlyStreakFuture = _service.calculatePornOnlyStreak();
    final mastOnlyStreakFuture = _service.calculateMastOnlyStreak();
    final slipUpStreakFuture = _service.calculateSlipUpStreak();

    final results = await Future.wait([
      userFirstDateFuture,
      relapseStreakFuture,
      pornOnlyStreakFuture,
      mastOnlyStreakFuture,
      slipUpStreakFuture,
    ]);

    var streaks = StreakStatistics(
      userFirstDate: results[0] as DateTime,
      relapseStreak: results[1] as int,
      pornOnlyStreak: results[2] as int,
      mastOnlyStreak: results[3] as int,
      slipUpStreak: results[4] as int,
    );

    state = AsyncValue.data(streaks);
  }
}

@Riverpod(keepAlive: true)
StreakService streakService(StreakServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = StreakRepository(firestore);
  return StreakService(repository);
}

@riverpod
Stream<StreakStatistics> streakStream(StreakStreamRef ref) {
  final service = ref.read(streakServiceProvider);
  return service.streakStatisticsStream();
}
