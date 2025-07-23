import 'package:reboot_app_3/features/vault/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_repository.dart';

class StreakService {
  final StreakRepository _repository;

  StreakService(this._repository);

  Future<DateTime> getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }

  // Get the duration for relapse streak (for detailed display)
  Future<Duration> getRelapseStreakDuration() async {
    final userFirstDate = await getUserFirstDate();
    final relapseFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.relapse);

    if (relapseFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate);
    } else {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = relapseFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate);
    }
  }

  // Get the duration for pornOnly streak (for detailed display)
  Future<Duration> getPornOnlyStreakDuration() async {
    final userFirstDate = await getUserFirstDate();
    final pornOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.pornOnly);

    if (pornOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate);
    } else {
      pornOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = pornOnlyFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate);
    }
  }

  // Get the duration for mastOnly streak (for detailed display)
  Future<Duration> getMastOnlyStreakDuration() async {
    final userFirstDate = await getUserFirstDate();
    final mastOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.mastOnly);

    if (mastOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate);
    } else {
      mastOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = mastOnlyFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate);
    }
  }

  // Get the duration for slipUp streak (for detailed display)
  Future<Duration> getSlipUpStreakDuration() async {
    final userFirstDate = await getUserFirstDate();
    final slipUpFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.slipUp);

    if (slipUpFollowUps.isEmpty) {
      final relapseFollowUps =
          await _repository.readFollowUpsByType(FollowUpType.relapse);

      if (relapseFollowUps.isEmpty) {
        return DateTime.now().difference(userFirstDate);
      } else {
        relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
        final lastRelapseDate = relapseFollowUps.first.time;
        return DateTime.now().difference(lastRelapseDate);
      }
    } else {
      slipUpFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = slipUpFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate);
    }
  }

  Future<int> calculateRelapseStreak() async {
    final duration = await getRelapseStreakDuration();
    return duration.inDays;
  }

  Future<int> calculatePornOnlyStreak() async {
    final duration = await getPornOnlyStreakDuration();
    return duration.inDays;
  }

  Future<int> calculateMastOnlyStreak() async {
    final duration = await getMastOnlyStreakDuration();
    return duration.inDays;
  }

  Future<int> calculateSlipUpStreak() async {
    final duration = await getSlipUpStreakDuration();
    return duration.inDays;
  }

  Stream<StreakStatistics> streakStatisticsStream() async* {
    while (true) {
      final userFirstDate = await getUserFirstDate();
      final followUps = await Future.wait([
        _repository.readFollowUpsByType(FollowUpType.relapse),
        _repository.readFollowUpsByType(FollowUpType.pornOnly),
        _repository.readFollowUpsByType(FollowUpType.mastOnly),
        _repository.readFollowUpsByType(FollowUpType.slipUp),
      ]);

      final relapseStreak = _calculateStreak(followUps[0], userFirstDate);
      final pornOnlyStreak = _calculateStreak(followUps[1], userFirstDate);
      final mastOnlyStreak = _calculateStreak(followUps[2], userFirstDate);
      final slipUpStreak = _calculateStreak(followUps[3], userFirstDate);

      yield StreakStatistics(
        userFirstDate: userFirstDate,
        relapseStreak: relapseStreak,
        pornOnlyStreak: pornOnlyStreak,
        mastOnlyStreak: mastOnlyStreak,
        slipUpStreak: slipUpStreak,
      );

      await Future.delayed(Duration(minutes: 1));
    }
  }

  int _calculateStreak(List<FollowUpModel> followUps, DateTime userFirstDate) {
    if (followUps.isEmpty) {
      return DateTime.now().difference(userFirstDate).inDays;
    } else {
      followUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = followUps.first.time;
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }
}
