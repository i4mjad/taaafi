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

  /// Creates multiple follow-ups in Firestore.
  Future<void> createMultipleFollowUps({
    required List<FollowUpModel> followUps,
  }) async {
    await _repository.createMultipleFollowUps(followUps: followUps);
  }

  /// Reads all follow-ups for the user.
  Future<List<FollowUpModel>> readAllFollowUps() async {
    return await _repository.readAllFollowUps();
  }

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
  Future<int> calculateTotalDaysFromFirstDate() async {
    return await _repository.calculateTotalDaysFromFirstDate();
  }

  /// Calculate the longest relapse streak.
  Future<int> calculateLongestRelapseStreak() async {
    final followUps =
        await _repository.readFollowUpsByType(FollowUpType.relapse);
    if (followUps.isEmpty) return 0;

    followUps.sort((a, b) => a.time.compareTo(b.time));
    int longestStreak = 0;
    int currentStreak = 1;

    for (int i = 1; i < followUps.length; i++) {
      if (followUps[i].time.difference(followUps[i - 1].time).inDays == 1) {
        currentStreak++;
      } else {
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 1;
      }
    }

    return longestStreak > currentStreak ? longestStreak : currentStreak;
  }
}
