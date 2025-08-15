import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/repositories/ban_repository.dart';
import '../data/repositories/warning_repository.dart';
import '../application/clean_ban_service.dart';
import '../application/clean_warning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'clean_ban_warning_providers.g.dart';

// ==================== REPOSITORIES ====================

@riverpod
BanRepository banRepository(Ref ref) {
  return BanRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}

@riverpod
WarningRepository warningRepository(Ref ref) {
  return WarningRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}

// ==================== SERVICES ====================

@riverpod
CleanBanService cleanBanService(Ref ref) {
  final repository = ref.watch(banRepositoryProvider);
  return CleanBanService(repository);
}

@riverpod
CleanWarningService cleanWarningService(Ref ref) {
  final repository = ref.watch(warningRepositoryProvider);
  return CleanWarningService(repository);
}

// ==================== CURRENT USER DATA ====================

@riverpod
Future<List<Ban>> currentUserBans(Ref ref) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.getCurrentUserBans();
}

@riverpod
Future<List<Warning>> currentUserWarnings(Ref ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getCurrentUserWarnings();
}

@riverpod
Future<List<Warning>> currentUserHighPriorityWarnings(Ref ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getCurrentUserHighPriorityWarnings();
}

// ==================== USER-SPECIFIC DATA ====================

@riverpod
Future<List<Ban>> userBans(Ref ref, String userId) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.getUserBans(userId);
}

@riverpod
Future<List<Warning>> userWarnings(Ref ref, String userId) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.getUserWarnings(userId);
}

// ==================== STATUS CHECKS ====================

@riverpod
Future<bool> isCurrentUserBannedFromApp(Ref ref) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.currentUserHasAppWideBans();
}

@riverpod
Future<bool> currentUserHasCriticalWarnings(Ref ref) async {
  final service = ref.watch(cleanWarningServiceProvider);
  return await service.currentUserHasCriticalWarnings();
}

// ==================== FEATURE ACCESS ====================

@riverpod
Future<bool> canCurrentUserAccessFeature(
    Ref ref, String featureUniqueName) async {
  final service = ref.watch(cleanBanServiceProvider);
  return await service.canCurrentUserAccessFeature(featureUniqueName);
}

@riverpod
Future<Ban?> currentUserFeatureBan(Ref ref, String featureUniqueName) async {
  final service = ref.watch(cleanBanServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return await service.getUserFeatureBan(userId, featureUniqueName);
}

// ==================== SUMMARY DATA ====================

@riverpod
Future<BanStatusSummary> currentUserBanSummary(Ref ref) async {
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
Future<WarningStatusSummary> currentUserWarningSummary(Ref ref) async {
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
Stream<List<Ban>> currentUserBansStream(Ref ref) {
  final service = ref.watch(cleanBanServiceProvider);
  return service.watchCurrentUserBans();
}

@riverpod
Stream<List<Warning>> currentUserWarningsStream(Ref ref) {
  final service = ref.watch(cleanWarningServiceProvider);
  return service.watchCurrentUserWarnings();
}

// ==================== HELPER PROVIDERS ====================

@riverpod
String? currentUserId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

/// Provider that invalidates cache when user changes
@riverpod
Future<void> invalidateUserCache(Ref ref) async {
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
