import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/ban.dart';
import '../data/repositories/ban_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clean_ban_service.g.dart';

/// Clean ban service that delegates to repository (business logic layer)
class CleanBanService {
  final BanRepository _repository;

  CleanBanService(this._repository);

  // ==================== USER BAN QUERIES ====================

  /// Get all bans for a user
  Future<List<Ban>> getUserBans(String userId) async {
    return await _repository.getUserBans(userId);
  }

  /// Get current user bans
  Future<List<Ban>> getCurrentUserBans() async {
    return await _repository.getCurrentUserBans();
  }

  /// Check if user can access a feature (business logic)
  Future<bool> canUserAccessFeature(
      String userId, String featureUniqueName) async {
    final ban = await _repository.getUserFeatureBan(userId, featureUniqueName);
    return ban == null; // No ban means access allowed
  }

  /// Check if current user can access a feature
  Future<bool> canCurrentUserAccessFeature(String featureUniqueName) async {
    final bans = await _repository.getCurrentUserBans();

    // Check for app-wide bans first
    if (bans.any((ban) => ban.scope == BanScope.app_wide)) {
      return false;
    }

    // Check for feature-specific bans
    return !bans.any((ban) =>
        ban.scope == BanScope.feature_specific &&
        ban.restrictedFeatures != null &&
        ban.restrictedFeatures!.contains(featureUniqueName));
  }

  /// Check if user has app-wide bans
  Future<bool> hasAppWideBans(String userId) async {
    return await _repository.hasAppWideBans(userId);
  }

  /// Check if current user has app-wide bans
  Future<bool> currentUserHasAppWideBans() async {
    return await _repository.currentUserHasAppWideBans();
  }

  /// Get feature-specific ban for user
  Future<Ban?> getUserFeatureBan(
      String userId, String featureUniqueName) async {
    return await _repository.getUserFeatureBan(userId, featureUniqueName);
  }

  // ==================== DEVICE TRACKING ====================

  /// Get bans by device IDs
  Future<List<Ban>> getBansByDeviceIds(List<String> deviceIds) async {
    return await _repository.getBansByDeviceIds(deviceIds);
  }

  /// Get device ban history
  Future<List<Ban>> getDeviceBanHistory(String userId, {int limit = 20}) async {
    return await _repository.getDeviceBanHistory(userId, limit: limit);
  }

  // ==================== REAL-TIME DATA ====================

  /// Stream of user bans
  Stream<List<Ban>> watchUserBans(String userId) {
    return _repository.watchUserBans(userId);
  }

  /// Stream of current user bans
  Stream<List<Ban>> watchCurrentUserBans() {
    return _repository.watchCurrentUserBans();
  }

  // ==================== BUSINESS LOGIC HELPERS ====================

  /// Calculate ban status summary for user
  Future<BanStatusSummary> getBanStatusSummary(String userId) async {
    final bans = await getUserBans(userId);

    final appWideBans =
        bans.where((ban) => ban.scope == BanScope.app_wide).toList();
    final featureBans =
        bans.where((ban) => ban.scope == BanScope.feature_specific).toList();

    return BanStatusSummary(
      hasAppWideBans: appWideBans.isNotEmpty,
      hasFeatureBans: featureBans.isNotEmpty,
      totalBans: bans.length,
      activeBans: bans.where((ban) => ban.isCurrentlyActive).length,
      permanentBans:
          bans.where((ban) => ban.severity == BanSeverity.permanent).length,
    );
  }

  /// Generate feature access map for user
  Future<Map<String, bool>> generateFeatureAccessMap(
      String userId, List<String> featureNames) async {
    final accessMap = <String, bool>{};

    for (final featureName in featureNames) {
      accessMap[featureName] = await canUserAccessFeature(userId, featureName);
    }

    return accessMap;
  }
}

/// Business logic data class for ban status
class BanStatusSummary {
  final bool hasAppWideBans;
  final bool hasFeatureBans;
  final int totalBans;
  final int activeBans;
  final int permanentBans;

  const BanStatusSummary({
    required this.hasAppWideBans,
    required this.hasFeatureBans,
    required this.totalBans,
    required this.activeBans,
    required this.permanentBans,
  });

  bool get isUserBanned => hasAppWideBans || hasFeatureBans;
  bool get isInGoodStanding => !isUserBanned;
}

// ==================== PROVIDERS ====================

@riverpod
CleanBanService cleanBanService(Ref ref) {
  final repository = ref.watch(banRepositoryProvider);
  return CleanBanService(repository);
}
