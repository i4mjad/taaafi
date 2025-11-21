import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../application/referral_providers.dart';
import '../../data/models/referral_code_model.dart';
import '../../data/models/referral_stats_model.dart';
import '../../data/models/referral_verification_model.dart';

part 'referral_dashboard_provider.g.dart';

/// Provider for current user's ID
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

/// Provider for user's referral code
@riverpod
Future<ReferralCodeModel?> userReferralCode(UserReferralCodeRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(referralRepositoryProvider);
  return await repository.getUserReferralCode(userId);
}

/// Provider for referral stats
@riverpod
Future<ReferralStatsModel?> referralStats(ReferralStatsRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(referralRepositoryProvider);
  return await repository.getReferralStats(userId);
}

/// Provider for referred users list
@riverpod
Future<List<ReferralVerificationModel>> referredUsers(
    ReferredUsersRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(referralRepositoryProvider);
  return await repository.getReferredUsers(userId);
}

