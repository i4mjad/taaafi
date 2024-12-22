import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/follow_up_repository.dart';

/// A service that contains business logic or computation related to FollowUps.
class FollowUpService {
  final FollowUpRepository _repository;

  FollowUpService(this._repository);

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

  Future<DateTime> _getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }

  Future<DateTime> getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }

  /// Calculate the total number of follow-ups for the user.

  /// Calculate the streak (in days) for each FollowUpType.
  /// - If no follow-up of a given type exists,
  ///   we calculate the streak from the user's first date to now.

  Future<int> calculateRelapseStreak() async {
    final userFirstDate = await getUserFirstDate();
    final relapseFollowUps =
        await _repository.readFollowUpsByType(FollowUpType.relapse);

    if (relapseFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(relapseFollowUps.first.time);
      print(lastFollowUpDate);
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

  /// Calculate the longest streak (in days) between two `relapse` follow-ups.
  /// If there are fewer than 2 relapse follow-ups, returns 0.
  Future<int> calculateLongestRelapseStreak() async {
    final userFirstDate = await _getUserFirstDate();
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

    // Compute gaps
    int longest = 0;
    for (int i = 0; i < relapses.length - 1; i++) {
      final currentDate = _onlyDate(relapses[i].time);
      final nextDate = _onlyDate(relapses[i + 1].time);

      final diff = nextDate.difference(currentDate).inDays;
      if (diff > longest) {
        longest = diff;
      }
    }

    // Check the streak from the last relapse to now
    final lastRelapseDate = _onlyDate(relapses.last.time);
    final fromLastRelapseToNow =
        DateTime.now().difference(lastRelapseDate).inDays;
    if (fromLastRelapseToNow > longest) {
      longest = fromLastRelapseToNow;
    }

    return longest;
  }

  /// Calculate the days without relapse.
  Future<int> calculateDaysWithoutRelapse() async {
    return await _repository.calculateDaysWithoutRelapse();
  }

  /// Calculate the total days from the user's first date.
  Future<int> calculateTotalDaysFromFirstDate() async {
    return await _repository.calculateTotalDaysFromFirstDate();
  }

  /// A helper function that strips the time portion from a DateTime
  /// so that only the date is used (year-month-day).
  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
