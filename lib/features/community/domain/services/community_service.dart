import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/features/community/data/repositories/community_repository.dart';

/// Service for handling community-related business logic
class CommunityService {
  final CommunityRepository _repository;
  final SharedPreferences _prefs;

  CommunityService(this._repository, this._prefs);

  /// Records user interest in the community feature
  ///
  /// This method checks if the user has already recorded interest,
  /// and if not, records it in Firestore and updates local preferences.
  ///
  /// Returns true if interest was recorded, false if it was already recorded.
  Future<bool> recordInterest() async {
    try {
      final hasRecordedInterest =
          _prefs.getBool('community_interest_recorded') ?? false;

      if (!hasRecordedInterest) {
        await _repository.recordInterest();
        await _prefs.setBool('community_interest_recorded', true);
        return true;
      }

      return false;
    } catch (e) {
      // Let the notifier handle the error
      rethrow;
    }
  }
}
