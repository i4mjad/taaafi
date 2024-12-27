import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/follow_up_service.dart';
import 'package:reboot_app_3/features/home/data/models/user_statistics.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/follow_up_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'follow_up_notifier.g.dart';

@riverpod
class FollowUpNotifier extends _$FollowUpNotifier {
  late final FollowUpService _service;

  @override
  FutureOr<UserStatisticsModel> build() async {
    _service = ref.read(followUpServiceProvider);
    final daysWithoutRelapse = await _service.calculateDaysWithoutRelapse();
    final totalDaysFromFirstDate =
        await _service.calculateTotalDaysFromFirstDate();

    final longestRelapseStreak = await _service.calculateLongestRelapseStreak();
    return UserStatisticsModel(
      daysWithoutRelapse: daysWithoutRelapse,
      totalDaysFromFirstDate: totalDaysFromFirstDate,
      longestRelapseStreak: longestRelapseStreak,
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

  Future<void> createMultipleFollowUps(List<FollowUpModel> followUps) async {
    state = const AsyncValue.loading();
    try {
      await _service.createMultipleFollowUps(followUps: followUps);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
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
