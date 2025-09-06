import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../application/ban_warning_facade.dart';
import '../application/device_service.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/models/app_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'ban_warning_providers.g.dart';

// ==================== SERVICES ====================

@riverpod
BanWarningFacade banWarningFacade(Ref ref) {
  return BanWarningFacade();
}

@riverpod
DeviceService deviceService(Ref ref) {
  return DeviceService();
}

// ==================== USER BANS ====================

@riverpod
Future<List<Ban>> currentUserBans(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserBans();
}

@riverpod
Future<List<Ban>> userBans(Ref ref, String userId) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getUserBans(userId);
}

@riverpod
Future<bool> isCurrentUserBannedFromApp(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.isCurrentUserBannedFromApp();
}

// ==================== USER WARNINGS ====================

@riverpod
Future<List<Warning>> currentUserWarnings(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserWarnings();
}

@riverpod
Future<List<Warning>> userWarnings(Ref ref, String userId) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getUserWarnings(userId);
}

@riverpod
Future<List<Warning>> currentUserHighPriorityWarnings(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserHighPriorityWarnings();
}

// ==================== APP FEATURES ====================

@riverpod
Future<List<AppFeature>> appFeatures(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getAppFeatures();
}

@riverpod
Future<Map<String, bool>> featureAccess(Ref ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.generateFeatureAccessMap();
}

/// 🚀 LAZY LOADING: Check access for a specific feature only (much faster)
@riverpod
Future<bool> specificFeatureAccess(Ref ref, String featureUniqueName) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.canUserAccessFeature(featureUniqueName);
}

/// Get ban details for a specific feature (lazy loaded)
@riverpod
Future<Ban?> currentUserFeatureBan(Ref ref, String featureUniqueName) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserFeatureBan(featureUniqueName);
}

// ==================== DEVICE TRACKING ====================

@riverpod
Future<String> currentDeviceId(Ref ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getDeviceId();
}

@riverpod
Future<List<String>> currentUserDeviceIds(Ref ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getCurrentUserDeviceIds();
}

// ==================== DEVICE VIOLATION HISTORY ====================

@riverpod
Future<Map<String, List<dynamic>>> deviceViolationHistory(
    Ref ref, String userId) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getDeviceViolationHistory(userId);
}

// ==================== NOTIFIERS FOR REAL-TIME UPDATES ====================

@riverpod
class UserBanStatusNotifier extends _$UserBanStatusNotifier {
  @override
  Future<bool> build(String userId) async {
    final facade = ref.watch(banWarningFacadeProvider);
    final bans = await facade.getUserBans(userId);
    return bans.any((ban) => ban.scope == BanScope.app_wide);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final facade = ref.read(banWarningFacadeProvider);
      final bans = await facade.getUserBans(userId);
      return bans.any((ban) => ban.scope == BanScope.app_wide);
    });
  }
}

// ==================== HELPER PROVIDERS ====================

/// Provider that invalidates ban-related cache when user changes
@riverpod
Future<void> invalidateBanCache(Ref ref) async {
  // Listen to auth state changes
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      // User logged out, invalidate all cache
      ref.invalidate(currentUserBansProvider);
      ref.invalidate(currentUserWarningsProvider);
      ref.invalidate(currentUserHighPriorityWarningsProvider);
      ref.invalidate(isCurrentUserBannedFromAppProvider);
      ref.invalidate(featureAccessProvider);
    }
  });
}

/// Provider for getting user ID safely
@riverpod
String? currentUserId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}
