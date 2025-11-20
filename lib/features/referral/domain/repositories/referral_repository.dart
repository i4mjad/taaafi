import '../models/referral_code_model.dart';
import '../models/referral_stats_model.dart';

abstract class ReferralRepository {
  /// Get user's referral code by user ID
  Future<ReferralCodeModel?> getUserReferralCode(String userId);

  /// Get referral stats for a user
  Future<ReferralStatsModel?> getReferralStats(String userId);

  /// Validate if a referral code exists and is active
  Future<bool> validateReferralCode(String code);

  /// Get referral code details by code string
  Future<ReferralCodeModel?> getReferralCodeByCode(String code);
}
