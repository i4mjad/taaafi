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
}
