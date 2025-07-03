import 'package:firebase_auth/firebase_auth.dart';
import 'ban_warning_facade.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';

/// Security service that runs during app startup to check device/user bans
/// and initialize necessary tracking (DRY + Clean Architecture)
class StartupSecurityService {
  final BanWarningFacade _facade;
  final FirebaseAuth _auth;

  StartupSecurityService({
    BanWarningFacade? facade,
    FirebaseAuth? auth,
  })  : _facade = facade ?? BanWarningFacade(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Initialize security and device tracking during app startup
  Future<SecurityStartupResult> initializeAppSecurity() async {
    try {
      print('🔒 [DEBUG] Starting security initialization...');

      // Step 1: Initialize device tracking
      print('📱 [DEBUG] Step 1: Initializing device tracking...');
      await _facade.initializeDeviceTracking();
      print('✅ [DEBUG] Device tracking initialized');

      // Step 2: Get device ID for ban checking
      print('🔍 [DEBUG] Step 2: Getting device ID...');
      final deviceId = await _facade.getCurrentDeviceId();
      print('📱 [DEBUG] Device ID: $deviceId');

      // Step 3: Check for device-wide bans (most restrictive)
      print('🚫 [DEBUG] Step 3: Checking device bans...');
      final isDeviceBanned = await _checkDeviceBan(deviceId);
      print('🚫 [DEBUG] Device banned: $isDeviceBanned');
      if (isDeviceBanned) {
        print('❌ [DEBUG] Device is banned, returning device banned result');
        return SecurityStartupResult.deviceBanned(
          message:
              'This device has been restricted from accessing the application.',
          deviceId: deviceId,
        );
      }

      // Step 4: Check user-level bans if user is logged in
      final user = _auth.currentUser;
      print('👤 [DEBUG] Step 4: Checking user bans...');
      print('👤 [DEBUG] Current user: ${user?.uid ?? 'null'}');
      if (user != null) {
        print('🔍 [DEBUG] User is logged in, checking for user bans...');
        final isUserBanned = await _facade.isCurrentUserBannedFromApp();
        print('🚫 [DEBUG] User banned: $isUserBanned');

        // Additional debug: Get user bans directly
        try {
          final userBans = await _facade.getCurrentUserBans();
          print('📋 [DEBUG] Found ${userBans.length} total bans for user');
          for (int i = 0; i < userBans.length; i++) {
            final ban = userBans[i];
            print(
                '📋 [DEBUG] Ban $i: ID=${ban.id}, scope=${ban.scope}, isActive=${ban.isActive}, isExpired=${ban.isExpired}, isCurrentlyActive=${ban.isCurrentlyActive}');
          }
          final appWideBans =
              userBans.where((ban) => ban.scope == BanScope.app_wide).toList();
          print('🚫 [DEBUG] Found ${appWideBans.length} app-wide bans');
        } catch (e) {
          print('❌ [DEBUG] Error getting user bans for debugging: $e');
        }

        if (isUserBanned) {
          print('❌ [DEBUG] User is banned, returning user banned result');
          return SecurityStartupResult.userBanned(
            message:
                'Your account has been restricted from accessing the application.',
            userId: user.uid,
          );
        }
        print('✅ [DEBUG] User is not banned, continuing...');
      } else {
        print('👤 [DEBUG] No user logged in, skipping user ban check');
      }

      // Step 5: Pre-load feature access map for performance
      print('🗺️ [DEBUG] Step 5: Pre-loading feature access map...');
      final featureAccessMap = await _facade.generateFeatureAccessMap();
      print(
          '✅ [DEBUG] Feature access map loaded with ${featureAccessMap.length} features');

      print('✅ [DEBUG] Security initialization completed successfully');
      return SecurityStartupResult.success(
        message: 'Security initialization completed successfully',
        featureAccessMap: featureAccessMap,
        deviceId: deviceId,
      );
    } catch (e) {
      print('❌ [DEBUG] Security initialization failed: $e');
      // Fail safely - allow app to continue but log the error
      return SecurityStartupResult.warning(
        message: 'Security check failed, proceeding with limited functionality',
        error: e.toString(),
      );
    }
  }

  /// Check if device is banned (internal method)
  Future<bool> _checkDeviceBan(String deviceId) async {
    try {
      print('🔍 [DEBUG] Checking device ban for device: $deviceId');
      // Check for device-wide bans globally (not just current user)
      final deviceBans = await _facade.getDeviceBans(deviceId);
      print('📋 [DEBUG] Found ${deviceBans.length} device bans');
      for (int i = 0; i < deviceBans.length; i++) {
        final ban = deviceBans[i];
        print(
            '📋 [DEBUG] Device Ban $i: ID=${ban.id}, isActive=${ban.isActive}, isExpired=${ban.isExpired}');
      }

      // Device is banned if there are any active bans for this device
      final isBanned = deviceBans.isNotEmpty;
      print('🚫 [DEBUG] Device ban result: $isBanned');
      return isBanned;
    } catch (e) {
      print('❌ [DEBUG] Error checking device ban: $e');
      // Fail safely - if we can't check, allow access
      return false;
    }
  }

  /// Get current security status (for runtime checks)
  Future<SecurityStatus> getCurrentSecurityStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return SecurityStatus.unauthenticated();
      }

      final bans = await _facade.getCurrentUserBans();
      final warnings = await _facade.getCurrentUserWarnings();

      if (bans.any((ban) => ban.scope == BanScope.app_wide)) {
        return SecurityStatus.banned(bans: bans);
      }

      if (warnings.any((w) => w.severity == WarningSeverity.critical)) {
        return SecurityStatus.warning(warnings: warnings);
      }

      return SecurityStatus.active(
        bans: bans.where((b) => b.scope == BanScope.feature_specific).toList(),
        warnings: warnings,
      );
    } catch (e) {
      return SecurityStatus.error(error: e.toString());
    }
  }
}

// ==================== RESULT CLASSES ====================

/// Result of security initialization during app startup
class SecurityStartupResult {
  final SecurityStartupStatus status;
  final String message;
  final String? deviceId;
  final String? userId;
  final String? error;
  final Map<String, bool>? featureAccessMap;

  const SecurityStartupResult._({
    required this.status,
    required this.message,
    this.deviceId,
    this.userId,
    this.error,
    this.featureAccessMap,
  });

  factory SecurityStartupResult.success({
    required String message,
    required String deviceId,
    Map<String, bool>? featureAccessMap,
  }) =>
      SecurityStartupResult._(
        status: SecurityStartupStatus.success,
        message: message,
        deviceId: deviceId,
        featureAccessMap: featureAccessMap,
      );

  factory SecurityStartupResult.deviceBanned({
    required String message,
    required String deviceId,
  }) =>
      SecurityStartupResult._(
        status: SecurityStartupStatus.deviceBanned,
        message: message,
        deviceId: deviceId,
      );

  factory SecurityStartupResult.userBanned({
    required String message,
    required String userId,
  }) =>
      SecurityStartupResult._(
        status: SecurityStartupStatus.userBanned,
        message: message,
        userId: userId,
      );

  factory SecurityStartupResult.warning({
    required String message,
    required String error,
  }) =>
      SecurityStartupResult._(
        status: SecurityStartupStatus.warning,
        message: message,
        error: error,
      );

  bool get isBlocked =>
      status == SecurityStartupStatus.deviceBanned ||
      status == SecurityStartupStatus.userBanned;

  bool get isSuccess => status == SecurityStartupStatus.success;

  bool get hasWarning => status == SecurityStartupStatus.warning;
}

enum SecurityStartupStatus {
  success,
  deviceBanned,
  userBanned,
  warning,
}

/// Runtime security status
class SecurityStatus {
  final SecurityStatusType type;
  final List<Ban>? bans;
  final List<Warning>? warnings;
  final String? error;

  const SecurityStatus._({
    required this.type,
    this.bans,
    this.warnings,
    this.error,
  });

  factory SecurityStatus.unauthenticated() => const SecurityStatus._(
        type: SecurityStatusType.unauthenticated,
      );

  factory SecurityStatus.active({
    List<Ban>? bans,
    List<Warning>? warnings,
  }) =>
      SecurityStatus._(
        type: SecurityStatusType.active,
        bans: bans,
        warnings: warnings,
      );

  factory SecurityStatus.banned({required List<Ban> bans}) => SecurityStatus._(
        type: SecurityStatusType.banned,
        bans: bans,
      );

  factory SecurityStatus.warning({required List<Warning> warnings}) =>
      SecurityStatus._(
        type: SecurityStatusType.warning,
        warnings: warnings,
      );

  factory SecurityStatus.error({required String error}) => SecurityStatus._(
        type: SecurityStatusType.error,
        error: error,
      );

  bool get isBanned => type == SecurityStatusType.banned;
  bool get hasWarnings => type == SecurityStatusType.warning;
  bool get isActive => type == SecurityStatusType.active;
}

enum SecurityStatusType {
  unauthenticated,
  active,
  banned,
  warning,
  error,
}
