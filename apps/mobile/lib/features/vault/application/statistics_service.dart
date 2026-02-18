import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/statistics/statistics_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/user_statistics.dart';

/// A service that contains business logic or computation related to FollowUps.
class StatisticsService {
  final StatisticsRepository _repository;

  StatisticsService(this._repository);

  /// Creates a new follow-up in Firestore.
  Future<void> createFollowUp({
    required FollowUpModel followUp,
  }) async {
    await _repository.createFollowUp(followUp: followUp);
  }

  /// Reads all follow-ups for the user.

  /// Updates an existing follow-up.
  Future<void> updateFollowUp({
    required FollowUpModel followUp,
  }) async {
    await _repository.updateFollowUp(followUp: followUp);
  }

  /// Deletes a single follow-up by its ID.
  Future<void> deleteFollowUp({
    required String followUpId,
  }) async {
    await _repository.deleteFollowUp(followUpId: followUpId);
  }

  /// Deletes all follow-ups for the user.
  Future<void> deleteAllFollowUps() async {
    await _repository.deleteAllFollowUps();
  }

  // -------------------------------------------------------------------------
  // Calculation / Stats methods
  // -------------------------------------------------------------------------

  Future<int> calculateTotalFollowUps() async {
    return await _repository.calculateTotalFollowUps();
  }

  /// Calculate the days without relapse.
  Future<int> calculateDaysWithoutRelapse() async {
    return await _repository.calculateDaysWithoutRelapse();
  }

  /// Calculate the total days from the user's first date.
  Future<int> getRelapsesInLast30Days() async {
    return await _repository.getRelapsesInLast30Days();
  }

  /// Calculate the longest streak (in days) between two `relapse` follow-ups.
  /// If there are fewer than 2 relapse follow-ups, returns 0.
  Future<int> calculateLongestRelapseStreak() async {
    final userFirstDate = await _repository.getUserFirstDate();
    final relapses =
        await _repository.readFollowUpsByType(FollowUpType.relapse);

    if (relapses.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    }

    if (relapses.length == 1) {
      final firstRelapseDate = _onlyDate(relapses.first.time);
      final fromFirstDate =
          firstRelapseDate.difference(_onlyDate(userFirstDate)).inDays;
      final fromRelapseToNow =
          DateTime.now().difference(firstRelapseDate).inDays;
      return fromRelapseToNow > fromFirstDate
          ? fromRelapseToNow
          : fromFirstDate;
    }

    int longest = 0;
    for (int i = 0; i < relapses.length - 1; i++) {
      final currentDate = _onlyDate(relapses[i].time);
      final nextDate = _onlyDate(relapses[i + 1].time);

      final diff = nextDate.difference(currentDate).inDays;
      if (diff > longest) {
        longest = diff;
      }
    }

    final lastRelapseDate = _onlyDate(relapses.last.time);
    final fromLastRelapseToNow =
        DateTime.now().difference(lastRelapseDate).inDays;
    if (fromLastRelapseToNow > longest) {
      longest = fromLastRelapseToNow;
    }

    return longest;
  }

  Stream<UserStatisticsModel> userStatisticsStream() async* {
    while (true) {
      final futures = await Future.wait([
        calculateDaysWithoutRelapse(),
        getRelapsesInLast30Days(),
        calculateLongestRelapseStreak(),
      ]);

      yield UserStatisticsModel(
        daysWithoutRelapse: futures[0],
        totalDaysFromFirstDate: futures[1],
        longestRelapseStreak: futures[2],
      );

      await Future.delayed(Duration(minutes: 1));
    }
  }

  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
