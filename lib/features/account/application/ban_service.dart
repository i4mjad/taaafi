import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/ban.dart';
import 'device_service.dart';

/// Service responsible for ban-related operations only (SRP)
class BanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceService _deviceService = DeviceService();

  // ==================== BAN QUERIES ====================

  /// Get user's active bans
  Future<List<Ban>> getUserBans(String userId) async {
    try {
      print('🔍 [BAN_SERVICE] Querying Firestore for user bans...');
      print('👤 [BAN_SERVICE] User ID: $userId');

      final querySnapshot = await _firestore
          .collection('bans')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      print(
          '📋 [BAN_SERVICE] Firestore returned ${querySnapshot.docs.length} documents');

      final allBans =
          querySnapshot.docs.map((doc) => Ban.fromFirestore(doc)).toList();
      print('📋 [BAN_SERVICE] Mapped to ${allBans.length} ban objects');

      for (int i = 0; i < allBans.length; i++) {
        final ban = allBans[i];
        print(
            '📋 [BAN_SERVICE] Raw Ban $i: ID=${ban.id}, scope=${ban.scope}, isActive=${ban.isActive}, expiresAt=${ban.expiresAt}, isExpired=${ban.isExpired}, isCurrentlyActive=${ban.isCurrentlyActive}');
      }

      final activeBans = allBans.where((ban) => ban.isCurrentlyActive).toList();
      print(
          '✅ [BAN_SERVICE] Filtered to ${activeBans.length} currently active bans');

      return activeBans;
    } catch (e) {
      print('❌ [BAN_SERVICE] Error fetching user bans: $e');
      throw BanServiceException('Error fetching user bans: $e');
    }
  }

  /// Check if user is banned from a specific feature
  Future<bool> isUserBannedFromFeature(
      String userId, String featureUniqueName) async {
    try {
      final bans = await getUserBans(userId);

      for (final ban in bans) {
        // Check for app-wide bans (user_ban and device_ban)
        if (ban.scope == BanScope.app_wide) {
          return true;
        }

        // Check for feature-specific bans
        if (ban.scope == BanScope.feature_specific &&
            ban.restrictedFeatures != null &&
            ban.restrictedFeatures!.contains(featureUniqueName)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw BanServiceException('Error checking feature ban: $e');
    }
  }

  /// Check if device is banned
  Future<bool> isDeviceBanned(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('type', isEqualTo: BanType.device_ban.name)
          .where('isActive', isEqualTo: true)
          .where('restrictedDevices', arrayContains: deviceId)
          .get();

      final activeBans = querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();

      return activeBans.isNotEmpty;
    } catch (e) {
      throw BanServiceException('Error checking device ban: $e');
    }
  }

  /// Check if current user can perform an action on a specific feature
  Future<bool> canUserPerformAction(String featureUniqueName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check device ban first
      final deviceId = await _deviceService.getDeviceId();
      if (await isDeviceBanned(deviceId)) {
        return false;
      }

      // Check user-specific bans
      return !(await isUserBannedFromFeature(user.uid, featureUniqueName));
    } catch (e) {
      throw BanServiceException('Error checking user action permission: $e');
    }
  }

  /// Check if current user has any app-wide ban
  Future<bool> isCurrentUserBannedFromApp() async {
    try {
      print('🔍 [BAN_SERVICE] Checking if current user is banned from app...');
      final user = _auth.currentUser;
      if (user == null) {
        print('👤 [BAN_SERVICE] No current user, returning false');
        return false;
      }

      print('👤 [BAN_SERVICE] Checking for user: ${user.uid}');

      // Check device ban
      print('📱 [BAN_SERVICE] Checking device ban...');
      final deviceId = await _deviceService.getDeviceId();
      print('📱 [BAN_SERVICE] Device ID: $deviceId');
      final isDeviceBannedResult = await isDeviceBanned(deviceId);
      print('🚫 [BAN_SERVICE] Device banned: $isDeviceBannedResult');
      if (isDeviceBannedResult) {
        print('❌ [BAN_SERVICE] Device is banned, returning true');
        return true;
      }

      // Check user ban
      print('👤 [BAN_SERVICE] Checking user bans...');
      final bans = await getUserBans(user.uid);
      print('📋 [BAN_SERVICE] Retrieved ${bans.length} user bans');

      for (int i = 0; i < bans.length; i++) {
        final ban = bans[i];
        print(
            '📋 [BAN_SERVICE] Ban $i: ID=${ban.id}, scope=${ban.scope}, type=${ban.type}, isActive=${ban.isActive}, isExpired=${ban.isExpired}, isCurrentlyActive=${ban.isCurrentlyActive}');
      }

      final appWideBans =
          bans.where((ban) => ban.scope == BanScope.app_wide).toList();
      print('🚫 [BAN_SERVICE] Found ${appWideBans.length} app-wide bans');

      final hasAppWideBan = bans.any((ban) => ban.scope == BanScope.app_wide);
      print('✅ [BAN_SERVICE] User has app-wide ban: $hasAppWideBan');
      return hasAppWideBan;
    } catch (e) {
      print('❌ [BAN_SERVICE] Error checking app ban: $e');
      throw BanServiceException('Error checking app ban: $e');
    }
  }

  /// Get ban details for specific feature
  Future<Ban?> getUserFeatureBan(
      String userId, String featureUniqueName) async {
    try {
      final bans = await getUserBans(userId);

      // First check for app-wide bans
      final appWideBan =
          bans.where((ban) => ban.scope == BanScope.app_wide).firstOrNull;
      if (appWideBan != null) return appWideBan;

      // Then check for feature-specific bans
      return bans
          .where((ban) =>
              ban.scope == BanScope.feature_specific &&
              ban.restrictedFeatures != null &&
              ban.restrictedFeatures!.contains(featureUniqueName))
          .firstOrNull;
    } catch (e) {
      throw BanServiceException('Error getting feature ban: $e');
    }
  }

  /// Get device history for violations (for admin panel)
  Future<Map<String, List<Ban>>> getDeviceBanHistory(String userId) async {
    try {
      final userDeviceIds = await _deviceService.getUserDeviceIds(userId);
      if (userDeviceIds.isEmpty) {
        return {'bans': []};
      }

      // Limit to 10 device IDs for Firestore query limitations
      final limitedDeviceIds = userDeviceIds.take(10).toList();

      // Query bans with matching device IDs
      final bansQuery = await _firestore
          .collection('bans')
          .where('deviceIds', arrayContainsAny: limitedDeviceIds)
          .orderBy('issuedAt', descending: true)
          .limit(20)
          .get();

      final bans = bansQuery.docs.map((doc) => Ban.fromFirestore(doc)).toList();

      return {'bans': bans};
    } catch (e) {
      throw BanServiceException('Error fetching device ban history: $e');
    }
  }

  /// Get all active bans for a specific device (global check)
  Future<List<Ban>> getDeviceBans(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('type', isEqualTo: BanType.device_ban.name)
          .where('isActive', isEqualTo: true)
          .where('restrictedDevices', arrayContains: deviceId)
          .get();

      return querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();
    } catch (e) {
      throw BanServiceException('Failed to get device bans: $e');
    }
  }

  // ==================== VALIDATION ====================

  /// Validate ban creation
  void validateBanCreation({
    required BanType type,
    required String reason,
    required BanSeverity severity,
    required List<String>? restrictedFeatures,
    DateTime? expiresAt,
  }) {
    // Reason is always required
    if (reason.trim().isEmpty) {
      throw BanValidationException('Reason is required');
    }

    // Feature bans require at least one feature
    if (type == BanType.feature_ban &&
        (restrictedFeatures == null || restrictedFeatures.isEmpty)) {
      throw BanValidationException(
          'At least one feature must be selected for feature bans');
    }

    // Temporary bans require expiration date
    if (severity == BanSeverity.temporary && expiresAt == null) {
      throw BanValidationException(
          'Expiration date is required for temporary bans');
    }

    // Expiration date must be in the future
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw BanValidationException('Expiration date must be in the future');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get scope for ban type (auto-determined)
  BanScope getScopeForBanType(BanType type) {
    switch (type) {
      case BanType.user_ban:
      case BanType.device_ban:
        return BanScope.app_wide;
      case BanType.feature_ban:
        return BanScope.feature_specific;
    }
  }

  /// Check if ban is expired
  bool isBanExpired(Ban ban) {
    return ban.isExpired;
  }
}

// ==================== EXCEPTIONS ====================

class BanServiceException implements Exception {
  final String message;
  BanServiceException(this.message);

  @override
  String toString() => 'BanServiceException: $message';
}

class BanValidationException implements Exception {
  final String message;
  BanValidationException(this.message);

  @override
  String toString() => 'BanValidationException: $message';
}
