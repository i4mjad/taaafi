import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../application/ban_warning_facade.dart';
import '../application/device_service.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/models/app_feature.dart';

part 'ban_warning_providers.g.dart';

// ==================== SERVICES ====================

@riverpod
BanWarningFacade banWarningFacade(BanWarningFacadeRef ref) {
  return BanWarningFacade();
}

@riverpod
DeviceService deviceService(DeviceServiceRef ref) {
  return DeviceService();
}

// ==================== USER BANS ====================

@riverpod
Future<List<Ban>> currentUserBans(CurrentUserBansRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserBans();
}

@riverpod
Future<List<Ban>> userBans(UserBansRef ref, String userId) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getUserBans(userId);
}

@riverpod
Future<bool> isCurrentUserBannedFromApp(
    IsCurrentUserBannedFromAppRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.isCurrentUserBannedFromApp();
}

// ==================== USER WARNINGS ====================

@riverpod
Future<List<Warning>> currentUserWarnings(CurrentUserWarningsRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserWarnings();
}

@riverpod
Future<List<Warning>> userWarnings(UserWarningsRef ref, String userId) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getUserWarnings(userId);
}

@riverpod
Future<List<Warning>> currentUserHighPriorityWarnings(
    CurrentUserHighPriorityWarningsRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getCurrentUserHighPriorityWarnings();
}

// ==================== APP FEATURES ====================

@riverpod
Future<List<AppFeature>> appFeatures(AppFeaturesRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.getAppFeatures();
}

@riverpod
Future<Map<String, bool>> featureAccess(FeatureAccessRef ref) async {
  final facade = ref.watch(banWarningFacadeProvider);
  return await facade.generateFeatureAccessMap();
}

// ==================== DEVICE TRACKING ====================

@riverpod
Future<String> currentDeviceId(CurrentDeviceIdRef ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getDeviceId();
}

@riverpod
Future<List<String>> currentUserDeviceIds(CurrentUserDeviceIdsRef ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getCurrentUserDeviceIds();
}

// ==================== DEVICE VIOLATION HISTORY ====================

@riverpod
Future<Map<String, List<dynamic>>> deviceViolationHistory(
    DeviceViolationHistoryRef ref, String userId) async {
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
Future<void> invalidateBanCache(InvalidateBanCacheRef ref) async {
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
String? currentUserId(CurrentUserIdRef ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}
