import 'package:reboot_app_3/features/home/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/streak_repository.dart';

class StreakService {
  final StreakRepository _repository;

  StreakService(this._repository);

  Future<DateTime> getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }

  Future<int> calculateRelapseStreak() async {
    final userFirstDate = await getUserFirstDate();
    final relapseFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.relapse);

    if (relapseFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(relapseFollowUps.first.time);
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculatePornOnlyStreak() async {
    final userFirstDate = await getUserFirstDate();
    final pornOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.pornOnly);

    if (pornOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      pornOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(pornOnlyFollowUps.first.time);
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculateMastOnlyStreak() async {
    final userFirstDate = await getUserFirstDate();
    final mastOnlyFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.mastOnly);

    if (mastOnlyFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      mastOnlyFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(mastOnlyFollowUps.first.time);
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  Future<int> calculateSlipUpStreak() async {
    final userFirstDate = await getUserFirstDate();
    final slipUpFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.slipUp);

    if (slipUpFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      slipUpFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(slipUpFollowUps.first.time);
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
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      followUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(followUps.first.time);
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
