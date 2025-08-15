import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/application/streak_service.dart';
import 'package:reboot_app_3/features/vault/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';

part 'streak_notifier.g.dart';

@riverpod
class StreakNotifier extends _$StreakNotifier {
  StreakService get service => ref.read(streakServiceProvider);

  @override
  FutureOr<StreakStatistics> build() async {
    // Wait until the user document is fully loaded and valid
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    if (userDocAsync.isLoading || userDocAsync.hasError) {
      return StreakStatistics(
        userFirstDate: DateTime.now(),
        relapseStreak: 0,
        pornOnlyStreak: 0,
        mastOnlyStreak: 0,
        slipUpStreak: 0,
      );
    }

    // If no document yet (null) we shouldn't proceed
    if (userDocAsync.value == null) {
      return StreakStatistics(
        userFirstDate: DateTime.now(),
        relapseStreak: 0,
        pornOnlyStreak: 0,
        mastOnlyStreak: 0,
        slipUpStreak: 0,
      );
    }

    // Avoid hitting Firestore if the account is not yet fully set-up.
    final accountStatus = ref.watch(accountStatusProvider);
    if (accountStatus != AccountStatus.ok) {
      // Return an empty, default object; UI that depends on real data is hidden
      // until the account status becomes `ok`, at which point the provider will
      // rebuild automatically.
      return StreakStatistics(
        userFirstDate: DateTime.now(),
        relapseStreak: 0,
        pornOnlyStreak: 0,
        mastOnlyStreak: 0,
        slipUpStreak: 0,
      );
    }

    final userFirstDateFuture = service.getUserFirstDate();
    final relapseStreakFuture = service.calculateRelapseStreak();
    final pornOnlyStreakFuture = service.calculatePornOnlyStreak();
    final mastOnlyStreakFuture = service.calculateMastOnlyStreak();
    final slipUpStreakFuture = service.calculateSlipUpStreak();

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
    final userFirstDateFuture = service.getUserFirstDate();
    final relapseStreakFuture = service.calculateRelapseStreak();
    final pornOnlyStreakFuture = service.calculatePornOnlyStreak();
    final mastOnlyStreakFuture = service.calculateMastOnlyStreak();
    final slipUpStreakFuture = service.calculateSlipUpStreak();

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
StreakService streakService(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = StreakRepository(firestore, ref);
  return StreakService(repository);
}

@riverpod
Stream<StreakStatistics> streakStream(Ref ref) {
  final service = ref.read(streakServiceProvider);
  return service.streakStatisticsStream();
}
