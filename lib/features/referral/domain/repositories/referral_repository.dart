import '../../data/models/referral_code_model.dart';
import '../../data/models/referral_stats_model.dart';
import '../../data/models/referral_verification_model.dart';
import '../entities/redemption_result.dart';
import '../entities/redemption_response.dart';
import '../entities/reward_breakdown.dart';

abstract class ReferralRepository {
  /// Get user's referral code by user ID
  Future<ReferralCodeModel?> getUserReferralCode(String userId);

  /// Get referral stats for a user
  Future<ReferralStatsModel?> getReferralStats(String userId);

  /// Get list of users referred by this user
  Future<List<ReferralVerificationModel>> getReferredUsers(String userId);

  /// Get real-time stream of user's verification progress
  Stream<ReferralVerificationModel?> getUserVerificationStream(String userId);

  /// Validate if a referral code exists and is active
  Future<bool> validateReferralCode(String code);

  /// Get referral code details by code string
  Future<ReferralCodeModel?> getReferralCodeByCode(String code);

  /// Redeem a referral code for the current user
  Future<RedemptionResult> redeemReferralCode(String code);

  /// Redeem accumulated referral rewards (Sprint 11)
  Future<RedemptionResponse> redeemReferralRewards();

  /// Get reward breakdown (Sprint 11)
  Future<RewardBreakdown?> getRewardBreakdown(String userId);
}
