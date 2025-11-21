import '../../data/models/referral_code_model.dart';
import '../../data/models/referral_stats_model.dart';
import '../../data/models/referral_verification_model.dart';
import '../entities/redemption_result.dart';

abstract class ReferralRepository {
  /// Get user's referral code by user ID
  Future<ReferralCodeModel?> getUserReferralCode(String userId);

  /// Get referral stats for a user
  Future<ReferralStatsModel?> getReferralStats(String userId);

  /// Get list of users referred by this user
  Future<List<ReferralVerificationModel>> getReferredUsers(String userId);

  /// Validate if a referral code exists and is active
  Future<bool> validateReferralCode(String code);

  /// Get referral code details by code string
  Future<ReferralCodeModel?> getReferralCodeByCode(String code);

  /// Redeem a referral code for the current user
  Future<RedemptionResult> redeemReferralCode(String code);
}
