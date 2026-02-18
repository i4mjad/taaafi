import 'package:flutter/material.dart';
import '../data/models/ban.dart';
import '../data/models/warning.dart';
import '../../../core/localization/localization.dart';

/// Utility class for formatting ban and warning display information (DRY)
class BanDisplayFormatter {
  // ==================== BAN FORMATTING ====================

  /// Format ban duration for display
  static String formatBanDuration(Ban ban, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (ban.severity == BanSeverity.permanent) {
      return localizations.translate('ban-duration-permanent');
    }

    if (ban.expiresAt == null) {
      return localizations.translate('ban-duration-unknown');
    }

    final now = DateTime.now();
    final difference = ban.expiresAt!.difference(now);

    if (difference.isNegative) {
      return localizations.translate('ban-duration-expired');
    }

    if (difference.inDays > 0) {
      return localizations
          .translate('ban-duration-days')
          .replaceAll('{count}', '${difference.inDays}');
    } else if (difference.inHours > 0) {
      return localizations
          .translate('ban-duration-hours')
          .replaceAll('{count}', '${difference.inHours}');
    } else {
      return localizations
          .translate('ban-duration-minutes')
          .replaceAll('{count}', '${difference.inMinutes}');
    }
  }

  /// Format ban scope for display
  static String formatBanScope(Ban ban, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (ban.scope) {
      case BanScope.app_wide:
        return localizations.translate('ban-scope-app-wide');
      case BanScope.feature_specific:
        return localizations.translate('ban-scope-feature');
    }
  }

  /// Format ban type for display
  static String formatBanType(Ban ban, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (ban.type) {
      case BanType.user_ban:
        return localizations.translate('ban-type-user');
      case BanType.device_ban:
        return localizations.translate('ban-type-device');
      case BanType.feature_ban:
        return localizations.translate('ban-type-feature');
    }
  }

  /// Format ban severity for display
  static String formatBanSeverity(Ban ban, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (ban.severity) {
      case BanSeverity.temporary:
        return localizations.translate('ban-severity-temporary');
      case BanSeverity.permanent:
        return localizations.translate('ban-severity-permanent');
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
