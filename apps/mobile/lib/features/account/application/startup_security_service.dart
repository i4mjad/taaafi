import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/services/persistent_device_id_service.dart';
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
  /// 🚀 OPTIMIZED: Removed expensive feature access map generation
  /// Feature access is now checked lazily when needed
  Future<SecurityStartupResult> initializeAppSecurity() async {
    try {
      // Step 0: PRE-AUTH device ban check against bannedDevices collection
      // This runs BEFORE login, so banned devices can't even reach the login screen
      final preAuthResult = await _checkBannedDevicesCollection();
      if (preAuthResult != null) {
        return preAuthResult;
      }

      // Step 1 & 2: Initialize device tracking and get device ID in parallel-ish
      // (initializeDeviceTracking internally gets device ID anyway)
      await _facade.initializeDeviceTracking();
      final deviceId = await _facade.getCurrentDeviceId();

      // Step 3: Check for device-wide bans (HIGHEST PRIORITY - blocks all access)
      final deviceBanResult = await _checkDeviceBan(deviceId);

      if (deviceBanResult.isBanned) {
        return SecurityStartupResult.deviceBanned(
          message: deviceBanResult.message,
          deviceId: deviceId,
        );
      } else if (deviceBanResult.hasError) {
        // For security, if we can't verify device ban status, we should be cautious
        // But we'll allow access with a warning rather than blocking completely
      }

      // Step 4: Check user-level bans if user is logged in (LOWER PRIORITY)
      final user = _auth.currentUser;
      if (user != null) {
        final isUserBanned = await _facade.isCurrentUserBannedFromApp();

        if (isUserBanned) {
          return SecurityStartupResult.userBanned(
            message:
                'Your account has been restricted from accessing the application.',
            userId: user.uid,
          );
        }
      }

      // 🚀 OPTIMIZATION: Removed generateFeatureAccessMap() call
      // This was making N Firestore queries (one per feature) at startup
      // Feature access is now checked lazily when the user accesses a feature
      // This saves significant startup time (potentially seconds)

      return SecurityStartupResult.success(
        message: 'Security initialization completed successfully',
        featureAccessMap: null, // Lazy load instead
        deviceId: deviceId,
      );
    } catch (e) {
      // Fail safely - allow app to continue but log the error
      return SecurityStartupResult.warning(
        message: 'Security check failed, proceeding with limited functionality',
        error: e.toString(),
      );
    }
  }

  /// Pre-auth check against the bannedDevices Firestore collection.
  /// Returns a SecurityStartupResult if device is banned, null otherwise.
  /// Fails open (returns null) if the check fails for any reason.
  Future<SecurityStartupResult?> _checkBannedDevicesCollection() async {
    try {
      final deviceId = await PersistentDeviceIdService.instance.getDeviceId();

      final bannedDeviceDoc = await FirebaseFirestore.instance
          .collection('bannedDevices')
          .doc(deviceId)
          .get();

      if (bannedDeviceDoc.exists) {
        final data = bannedDeviceDoc.data();
        if (data != null && data['isActive'] == true) {
          // Check if ban has expired
          final expiresAt = data['expiresAt'];
          if (expiresAt != null) {
            final expiryDate = (expiresAt as Timestamp).toDate();
            if (expiryDate.isBefore(DateTime.now())) {
              // Ban expired, allow access
              return null;
            }
          }

          return SecurityStartupResult.deviceBanned(
            message:
                'This device has been permanently restricted from accessing the application. Contact support if you believe this is an error.',
            deviceId: deviceId,
          );
        }
      }

      return null; // Device not banned
    } catch (e) {
      // Fail open — if we can't check, allow access
      return null;
    }
  }

  /// Enhanced device ban checking with robust error handling
  Future<DeviceBanCheckResult> _checkDeviceBan(String deviceId) async {
    try {
      // Method 1: Check for global device bans (bans that apply to all users on this device)
      try {
        final deviceBans = await _facade.getDeviceBans(deviceId);

        if (deviceBans.isNotEmpty) {
          return DeviceBanCheckResult.banned(
              'This device has been permanently restricted from accessing the application. Contact support if you believe this is an error.');
        }
      } catch (e) {
        // Continue to next method if this fails
      }

      // Method 2: Check for user-specific device bans (if user is logged in)
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final userBans = await _facade.getCurrentUserBans();

          // Look for device bans that apply to this specific device
          final userDeviceBans = userBans
              .where((ban) =>
                  ban.type == BanType.device_ban &&
                  ban.isCurrentlyActive &&
                  ban.deviceIds != null &&
                  ban.deviceIds!.contains(deviceId))
              .toList();

          if (userDeviceBans.isNotEmpty) {
            return DeviceBanCheckResult.banned(
              'This device has been restricted from accessing the application for your account. Contact support if you believe this is an error.',
            );
          }
        } catch (e) {
          // Continue to next method if this fails
        }
      }

      // Method 3: Fallback - check if device is in any user's device ban list
      // This is a simpler check that might work even if the main queries fail
      try {
        final fallbackResult = await _checkDeviceBanFallback(deviceId);
        if (fallbackResult.isBanned) {
          return fallbackResult;
        }
      } catch (fallbackError) {
        // Continue if fallback fails
      }

      return DeviceBanCheckResult.notBanned();
    } catch (e) {
      return DeviceBanCheckResult.error(
        'Critical error during device ban verification: $e',
      );
    }
  }

  /// Fallback method for checking device bans with simpler logic
  Future<DeviceBanCheckResult> _checkDeviceBanFallback(String deviceId) async {
    try {
      // Try to get device bans directly and check if any exist
      final deviceBans = await _facade.getDeviceBans(deviceId);

      if (deviceBans.isNotEmpty) {
        return DeviceBanCheckResult.banned(
          'This device has been restricted from accessing the application. '
          'Device access has been revoked due to policy violations. '
          'Please contact support for more information.',
        );
      }

      return DeviceBanCheckResult.notBanned();
    } catch (e) {
      throw e;
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

/// Result of device ban checking with enhanced error handling
class DeviceBanCheckResult {
  final bool isBanned;
  final bool hasError;
  final String message;
  final String? error;

  const DeviceBanCheckResult._({
    required this.isBanned,
    required this.hasError,
    required this.message,
    this.error,
  });

  factory DeviceBanCheckResult.banned(String message) => DeviceBanCheckResult._(
        isBanned: true,
        hasError: false,
        message: message,
      );

  factory DeviceBanCheckResult.notBanned() => DeviceBanCheckResult._(
        isBanned: false,
        hasError: false,
        message: 'Device is not banned',
      );

  factory DeviceBanCheckResult.error(String error) => DeviceBanCheckResult._(
        isBanned: false,
        hasError: true,
        message: 'Device ban check failed',
        error: error,
      );
}
