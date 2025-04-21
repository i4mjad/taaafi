import 'package:reboot_app_3/features/home/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/streak_repository.dart';

class StreakService {
  final StreakRepository _repository;

  StreakService(this._repository);

  Future<DateTime> getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }

  Future<List<FollowUpModel>> getFollowUpsByType(FollowUpType type) async {
    return await _repository.readFollowUpsByType(type);
  }

  Future<int> calculateRelapseStreak() async {
    final userFirstDate = await getUserFirstDate();
    final relapseFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.relapse);

    if (relapseFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate).inDays;
    } else {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = relapseFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculatePornOnlyStreak() async {
    final userFirstDate = await getUserFirstDate();
    final pornOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.pornOnly);

    if (pornOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate).inDays;
    } else {
      pornOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = pornOnlyFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculateMastOnlyStreak() async {
    final userFirstDate = await getUserFirstDate();
    final mastOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.mastOnly);

    if (mastOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(userFirstDate).inDays;
    } else {
      mastOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = mastOnlyFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculateSlipUpStreak() async {
    final userFirstDate = await getUserFirstDate();
    final slipUpFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.slipUp);

    if (slipUpFollowUps.isEmpty) {
      final relapseFollowUps =
          await _repository.readFollowUpsByType(FollowUpType.relapse);

      if (relapseFollowUps.isEmpty) {
        return DateTime.now().difference(userFirstDate).inDays;
      } else {
        relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
        final lastRelapseDate = relapseFollowUps.first.time;
        return DateTime.now().difference(lastRelapseDate).inDays;
      }
    } else {
      slipUpFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = slipUpFollowUps.first.time;
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
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
