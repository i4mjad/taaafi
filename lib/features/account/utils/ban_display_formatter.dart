import '../data/models/ban.dart';
import '../data/models/warning.dart';

/// Utility class for formatting ban and warning display information (DRY)
class BanDisplayFormatter {
  // ==================== BAN FORMATTING ====================

  /// Format ban duration for display
  static String formatBanDuration(Ban ban) {
    if (ban.severity == BanSeverity.permanent) {
      return 'Permanent';
    }

    if (ban.expiresAt == null) {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = ban.expiresAt!.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s)';
    } else {
      return '${difference.inMinutes} minute(s)';
    }
  }

  /// Format ban scope for display
  static String formatBanScope(Ban ban) {
    switch (ban.scope) {
      case BanScope.app_wide:
        return 'App-wide';
      case BanScope.feature_specific:
        return 'Feature';
    }
  }

  /// Format ban type for display
  static String formatBanType(Ban ban) {
    switch (ban.type) {
      case BanType.user_ban:
        return 'User Ban';
      case BanType.device_ban:
        return 'Device Ban';
      case BanType.feature_ban:
        return 'Feature Ban';
    }
  }

  /// Format ban severity for display
  static String formatBanSeverity(Ban ban) {
    switch (ban.severity) {
      case BanSeverity.temporary:
        return 'Temporary';
      case BanSeverity.permanent:
        return 'Permanent';
    }
  }

  // ==================== WARNING FORMATTING ====================

  /// Format warning severity for display
  static String formatWarningSeverity(Warning warning) {
    switch (warning.severity) {
      case WarningSeverity.low:
        return 'Low';
      case WarningSeverity.medium:
        return 'Medium';
      case WarningSeverity.high:
        return 'High';
      case WarningSeverity.critical:
        return 'Critical';
    }
  }

  /// Format warning type for display
  static String formatWarningType(Warning warning) {
    switch (warning.type) {
      case WarningType.content_violation:
        return 'Content Violation';
      case WarningType.inappropriate_behavior:
        return 'Inappropriate Behavior';
      case WarningType.spam:
        return 'Spam';
      case WarningType.harassment:
        return 'Harassment';
      case WarningType.other:
        return 'Other';
    }
  }

  // ==================== STATUS FORMATTING ====================

  /// Check if warning is high priority
  static bool isHighPriorityWarning(Warning warning) {
    return warning.severity == WarningSeverity.high ||
        warning.severity == WarningSeverity.critical;
  }

  /// Get display message for ban status
  static String getBanStatusMessage(List<Ban> bans) {
    if (bans.isEmpty) return 'Account in good standing';

    final appWideBans = bans.where((ban) => ban.scope == BanScope.app_wide);
    if (appWideBans.isNotEmpty) {
      return 'Account restricted';
    }

    return 'Some features restricted';
  }

  /// Get display message for warning status
  static String getWarningStatusMessage(List<Warning> warnings) {
    if (warnings.isEmpty) return 'No active warnings';

    final highPriorityCount =
        warnings.where((w) => isHighPriorityWarning(w)).length;

    if (highPriorityCount > 0) {
      return 'Active warnings ($highPriorityCount critical)';
    }

    return 'Active warnings';
  }
}
