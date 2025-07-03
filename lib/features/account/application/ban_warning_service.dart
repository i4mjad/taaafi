import 'ban_warning_facade.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../data/models/app_feature.dart';
import '../utils/ban_display_formatter.dart';

/// Legacy service for backward compatibility (Facade Pattern)
/// @deprecated Use BanWarningFacade directly
class BanWarningService {
  final BanWarningFacade _facade = BanWarningFacade();

  // ==================== BANS ====================

  /// Get user's active bans
  Future<List<Ban>> getUserBans(String userId) async {
    return await _facade.getUserBans(userId);
  }

  /// Check if user is banned from a specific feature
  Future<bool> isUserBannedFromFeature(
      String userId, String featureUniqueName) async {
    final canAccess = await _facade.canUserAccessFeature(featureUniqueName);
    return !canAccess;
  }

  /// Check if device is banned
  Future<bool> isDeviceBanned(String deviceId) async {
    // This method is not exposed in facade as it's internal logic
    // Return false for backward compatibility
    return false;
  }

  /// Check if current user can perform an action on a specific feature
  Future<bool> canUserPerformAction(String featureUniqueName) async {
    return await _facade.canUserAccessFeature(featureUniqueName);
  }

  /// Check if current user has any app-wide ban
  Future<bool> isCurrentUserBannedFromApp() async {
    return await _facade.isCurrentUserBannedFromApp();
  }

  /// Get ban details for specific feature
  Future<Ban?> getUserFeatureBan(
      String userId, String featureUniqueName) async {
    return await _facade.getCurrentUserFeatureBan(featureUniqueName);
  }

  // ==================== WARNINGS ====================

  /// Get user's active warnings
  Future<List<Warning>> getUserWarnings(String userId) async {
    return await _facade.getUserWarnings(userId);
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getCurrentUserHighPriorityWarnings() async {
    return await _facade.getCurrentUserHighPriorityWarnings();
  }

  // ==================== FEATURES ====================

  /// Get all app features
  Future<List<AppFeature>> getAppFeatures() async {
    return await _facade.getAppFeatures();
  }

  /// Get specific feature by unique name
  Future<AppFeature?> getFeatureByUniqueName(String uniqueName) async {
    return await _facade.getFeatureByUniqueName(uniqueName);
  }

  // ==================== DEVICE HISTORY ====================

  /// Get device history for violations (for admin panel)
  Future<Map<String, List<dynamic>>> getDeviceViolationHistory(
      String userId) async {
    return await _facade.getDeviceViolationHistory(userId);
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
    _facade.validateBanCreation(
      type: type,
      reason: reason,
      severity: severity,
      restrictedFeatures: restrictedFeatures,
      expiresAt: expiresAt,
    );
  }

  /// Validate warning creation
  void validateWarningCreation({
    required String reason,
  }) {
    _facade.validateWarningCreation(reason: reason);
  }

  // ==================== HELPER METHODS ====================

  /// Get scope for ban type (auto-determined)
  BanScope getScopeForBanType(BanType type) {
    return _facade.getScopeForBanType(type);
  }

  /// Check if ban is expired
  bool isBanExpired(Ban ban) {
    return _facade.isBanExpired(ban);
  }

  /// Format ban duration for display
  String formatBanDuration(Ban ban) {
    return BanDisplayFormatter.formatBanDuration(ban);
  }
}
