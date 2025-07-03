import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/repositories/ban_repository.dart';
import '../data/repositories/warning_repository.dart';
import '../application/clean_ban_service.dart';
import '../application/clean_warning_service.dart';

part 'clean_ban_warning_providers.g.dart';

// ==================== REPOSITORIES ====================

@riverpod
BanRepository banRepository(BanRepositoryRef ref) {
  return BanRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}

@riverpod
WarningRepository warningRepository(WarningRepositoryRef ref) {
  return WarningRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}

// ==================== SERVICES ====================

@riverpod
CleanBanService cleanBanService(CleanBanServiceRef ref) {
  final repository = ref.watch(banRepositoryProvider);
  return CleanBanService(repository);
}

@riverpod
CleanWarningService cleanWarningService(CleanWarningServiceRef ref) {
  final repository = ref.watch(warningRepositoryProvider);
  return CleanWarningService(repository);
}

// ==================== CURRENT USER DATA ====================

@riverpod
Future<List<Ban>> currentUserBans(CurrentUserBansRef ref) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.getCurrentUserBans();
}

@riverpod
Future<List<Warning>> currentUserWarnings(CurrentUserWarningsRef ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getCurrentUserWarnings();
}

@riverpod
Future<List<Warning>> currentUserHighPriorityWarnings(
    CurrentUserHighPriorityWarningsRef ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getCurrentUserHighPriorityWarnings();
}

// ==================== USER-SPECIFIC DATA ====================

@riverpod
Future<List<Ban>> userBans(UserBansRef ref, String userId) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.getUserBans(userId);
}

@riverpod
Future<List<Warning>> userWarnings(UserWarningsRef ref, String userId) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getUserWarnings(userId);
}

// ==================== STATUS CHECKS ====================

@riverpod
Future<bool> isCurrentUserBannedFromApp(
    IsCurrentUserBannedFromAppRef ref) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.currentUserHasAppWideBans();
}

@riverpod
Future<bool> currentUserHasCriticalWarnings(
    CurrentUserHasCriticalWarningsRef ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.currentUserHasCriticalWarnings();
}

// ==================== FEATURE ACCESS ====================

@riverpod
Future<bool> canCurrentUserAccessFeature(
    CanCurrentUserAccessFeatureRef ref, String featureUniqueName) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.canCurrentUserAccessFeature(featureUniqueName);
}

@riverpod
Future<Ban?> currentUserFeatureBan(
    CurrentUserFeatureBanRef ref, String featureUniqueName) async {
  final service = ref.watch(cleanBanServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return await service.getUserFeatureBan(userId, featureUniqueName);
}

// ==================== SUMMARY DATA ====================

@riverpod
Future<BanStatusSummary> currentUserBanSummary(
    CurrentUserBanSummaryRef ref) async {
  final service = ref.watch(cleanBanServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return const BanStatusSummary(
      hasAppWideBans: false,
      hasFeatureBans: false,
      totalBans: 0,
      activeBans: 0,
      permanentBans: 0,
    );
  }
  return await service.getBanStatusSummary(userId);
}

@riverpod
Future<WarningStatusSummary> currentUserWarningSummary(
    CurrentUserWarningSummaryRef ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return const WarningStatusSummary(
      totalWarnings: 0,
      criticalCount: 0,
      highCount: 0,
      mediumCount: 0,
      lowCount: 0,
    );
  }
  return await service.getWarningStatusSummary(userId);
}

// ==================== REAL-TIME STREAMS ====================

@riverpod
Stream<List<Ban>> currentUserBansStream(CurrentUserBansStreamRef ref) {
  final service = ref.watch(cleanBanServiceProvider);
  return service.watchCurrentUserBans();
}

@riverpod
Stream<List<Warning>> currentUserWarningsStream(
    CurrentUserWarningsStreamRef ref) {
  final service = ref.watch(cleanWarningServiceProvider);
  return service.watchCurrentUserWarnings();
}

// ==================== HELPER PROVIDERS ====================

@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

/// Provider that invalidates cache when user changes
@riverpod
Future<void> invalidateUserCache(InvalidateUserCacheRef ref) async {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      // User logged out, invalidate all cache
      ref.invalidate(currentUserBansProvider);
      ref.invalidate(currentUserWarningsProvider);
      ref.invalidate(currentUserHighPriorityWarningsProvider);
      ref.invalidate(isCurrentUserBannedFromAppProvider);
      ref.invalidate(currentUserHasCriticalWarningsProvider);
      ref.invalidate(currentUserBanSummaryProvider);
      ref.invalidate(currentUserWarningSummaryProvider);
    }
  });
}
