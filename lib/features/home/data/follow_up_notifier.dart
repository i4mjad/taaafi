import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/follow_up_service.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/follow_up_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_up_notifier.g.dart';

class UserStatistics {
  final int relapseStreak;
  final int pornOnlyStreak;
  final int mastOnlyStreak;
  final int slipUpStreak;
  final int longestRelapseStreak;
  final int daysWithoutRelapse;
  final int totalDaysFromFirstDate;
  final DateTime userFirstDate;

  UserStatistics({
    required this.relapseStreak,
    required this.pornOnlyStreak,
    required this.mastOnlyStreak,
    required this.slipUpStreak,
    required this.longestRelapseStreak,
    required this.daysWithoutRelapse,
    required this.totalDaysFromFirstDate,
    required this.userFirstDate,
  });
}

@riverpod
class FollowUpNotifier extends _$FollowUpNotifier {
  late final FollowUpService _service;

  @override
  FutureOr<UserStatistics> build() async {
    _service = ref.read(followUpServiceProvider);
    final userFirstDate = await _service.getUserFirstDate();
    final relapseStreak = await _service.calculateRelapseStreak();
    final pornOnlyStreak = await _service.calculatePornOnlyStreak();
    final mastOnlyStreak = await _service.calculateMastOnlyStreak();
    final slipUpStreak = await _service.calculateSlipUpStreak();
    final longestRelapseStreak = await _service.calculateLongestRelapseStreak();
    final daysWithoutRelapse = await _service.calculateDaysWithoutRelapse();
    final totalDaysFromFirstDate =
        await _service.calculateTotalDaysFromFirstDate();

    return UserStatistics(
      relapseStreak: relapseStreak,
      pornOnlyStreak: pornOnlyStreak,
      mastOnlyStreak: mastOnlyStreak,
      slipUpStreak: slipUpStreak,
      longestRelapseStreak: longestRelapseStreak,
      daysWithoutRelapse: daysWithoutRelapse,
      totalDaysFromFirstDate: totalDaysFromFirstDate,
      userFirstDate: userFirstDate,
    );
  }

  Future<int> calculateRelapseStreak() async {
    return await _service.calculateRelapseStreak();
  }

  Future<int> calculatePornOnlyStreak() async {
    return await _service.calculatePornOnlyStreak();
  }

  Future<int> calculateMastOnlyStreak() async {
    return await _service.calculateMastOnlyStreak();
  }

  Future<int> calculateSlipUpStreak() async {
    return await _service.calculateSlipUpStreak();
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

/// A provider for the [FollowUpService].
@Riverpod(keepAlive: true)
FollowUpService followUpService(FollowUpServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = FollowUpRepository(firestore);
  return FollowUpService(repository);
}
