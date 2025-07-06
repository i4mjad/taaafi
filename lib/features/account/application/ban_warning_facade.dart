import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/models/app_feature.dart';
import 'ban_service.dart';
import 'warning_service.dart';
import 'app_feature_service.dart';
import 'device_service.dart';

/// Facade that coordinates ban, warning, and feature services (Facade Pattern)
/// Provides a simplified interface for UI components (DIP compliance)
class BanWarningFacade {
  final BanService _banService;
  final WarningService _warningService;
  final AppFeatureService _featureService;
  final DeviceService _deviceService; // Used by services internally
  final FirebaseAuth _auth;

  BanWarningFacade({
    BanService? banService,
    WarningService? warningService,
    AppFeatureService? featureService,
    DeviceService? deviceService,
    FirebaseAuth? auth,
  })  : _banService = banService ?? BanService(),
        _warningService = warningService ?? WarningService(),
        _featureService = featureService ?? AppFeatureService(),
        _deviceService = deviceService ?? DeviceService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ==================== FEATURE ACCESS ====================

  /// Check if current user can access a specific feature
  Future<bool> canUserAccessFeature(String featureUniqueName) async {
    try {
      final result = await _banService.canUserPerformAction(featureUniqueName);
      return result;
    } catch (e) {
      return false; // Fail safe
    }
  }

  /// Generate feature access map for all features
  Future<Map<String, bool>> generateFeatureAccessMap() async {
    try {
      final features = await _featureService.getAppFeatures();

      final user = _auth.currentUser;
      if (user == null) {
        return {};
      }

      final accessMap = <String, bool>{};
      for (final feature in features) {
        final canAccess =
            await _banService.canUserPerformAction(feature.uniqueName);
        accessMap[feature.uniqueName] = canAccess;
      }

      return accessMap;
    } catch (e) {
      return {}; // Fail safe
    }
  }

  // ==================== USER STATUS ====================

  /// Get current user's active bans
  Future<List<Ban>> getCurrentUserBans() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await _banService.getUserBans(user.uid);
  }

  /// Get current user's active warnings
  Future<List<Warning>> getCurrentUserWarnings() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await _warningService.getUserWarnings(user.uid);
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getCurrentUserHighPriorityWarnings() async {
    return await _warningService.getCurrentUserHighPriorityWarnings();
  }

  /// Check if current user is banned from app
  Future<bool> isCurrentUserBannedFromApp() async {
    final result = await _banService.isCurrentUserBannedFromApp();
    return result;
  }

  // ==================== FEATURE DETAILS ====================

  /// Get ban details for specific feature
  Future<Ban?> getCurrentUserFeatureBan(String featureUniqueName) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _banService.getUserFeatureBan(user.uid, featureUniqueName);
  }

  /// Get all app features
  Future<List<AppFeature>> getAppFeatures() async {
    return await _featureService.getAppFeatures();
  }

  /// Get specific feature by unique name
  Future<AppFeature?> getFeatureByUniqueName(String uniqueName) async {
    return await _featureService.getFeatureByUniqueName(uniqueName);
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Get user bans (admin use)
  Future<List<Ban>> getUserBans(String userId) async {
    return await _banService.getUserBans(userId);
  }

  /// Get user warnings (admin use)
  Future<List<Warning>> getUserWarnings(String userId) async {
    return await _warningService.getUserWarnings(userId);
  }

  /// Get device violation history (admin use)
  Future<Map<String, List<dynamic>>> getDeviceViolationHistory(
      String userId) async {
    try {
      final banHistory = await _banService.getDeviceBanHistory(userId);
      final warningHistory =
          await _warningService.getDeviceWarningHistory(userId);

      return {
        'bans': banHistory['bans'] ?? [],
        'warnings': warningHistory,
      };
    } catch (e) {
      return {'bans': [], 'warnings': []};
    }
  }

  // ==================== VALIDATION ====================

  /// Validate ban creation (admin use)
  void validateBanCreation({
    required BanType type,
    required String reason,
    required BanSeverity severity,
    required List<String>? restrictedFeatures,
    DateTime? expiresAt,
  }) {
    _banService.validateBanCreation(
      type: type,
      reason: reason,
      severity: severity,
      restrictedFeatures: restrictedFeatures,
      expiresAt: expiresAt,
    );
  }

  /// Validate warning creation (admin use)
  void validateWarningCreation({
    required String reason,
  }) {
    _warningService.validateWarningCreation(reason: reason);
  }

  // ==================== DEVICE TRACKING ====================

  /// Initialize device tracking for current session
  Future<void> initializeDeviceTracking() async {
    return await _deviceService.initializeDeviceTracking();
  }

  /// Get current device ID
  Future<String> getCurrentDeviceId() async {
    return await _deviceService.getDeviceId();
  }

  // ==================== UTILITY ====================

  /// Check if ban is expired
  bool isBanExpired(Ban ban) {
    return _banService.isBanExpired(ban);
  }

  /// Get scope for ban type
  BanScope getScopeForBanType(BanType type) {
    return _banService.getScopeForBanType(type);
  }

  /// Get all active bans for a specific device (global check)
  Future<List<Ban>> getDeviceBans(String deviceId) async {
    try {
      return await _banService.getDeviceBans(deviceId);
    } catch (e) {
      throw BanServiceException('Failed to get device bans: $e');
    }
  }
}
