import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of smart alerts available
enum SmartAlertType {
  highRiskHour,
  streakVulnerability,
}

/// Settings model for smart alerts
class SmartAlertSettings {
  final bool isHighRiskHourEnabled;
  final bool isStreakVulnerabilityEnabled;
  final int? lastCalculatedRiskHour; // 0-23, null if not enough data
  final int?
      lastCalculatedVulnerableWeekday; // 1-7 (Mon-Sun), null if not enough data
  final int
      vulnerabilityAlertHour; // 0-23, hour for vulnerability alerts (default 8 AM)
  final DateTime? lastRiskHourCalculation;
  final DateTime? lastVulnerabilityCalculation;
  final DateTime? lastAlertSent; // To enforce max 1 alert per day
  final String? lastAlertType; // Type of last alert sent
  final bool hasPermissionDeniedBannerShown;

  const SmartAlertSettings({
    this.isHighRiskHourEnabled = true, // Default ON after consent
    this.isStreakVulnerabilityEnabled = true, // Default ON after consent
    this.lastCalculatedRiskHour,
    this.lastCalculatedVulnerableWeekday,
    this.vulnerabilityAlertHour = 8, // Default 8 AM
    this.lastRiskHourCalculation,
    this.lastVulnerabilityCalculation,
    this.lastAlertSent,
    this.lastAlertType,
    this.hasPermissionDeniedBannerShown = false,
  });

  /// Create from Firestore document
  factory SmartAlertSettings.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SmartAlertSettings(
      isHighRiskHourEnabled: data['isHighRiskHourEnabled'] ?? true,
      isStreakVulnerabilityEnabled:
          data['isStreakVulnerabilityEnabled'] ?? true,
      lastCalculatedRiskHour: data['lastCalculatedRiskHour'] as int?,
      lastCalculatedVulnerableWeekday:
          data['lastCalculatedVulnerableWeekday'] as int?,
      vulnerabilityAlertHour: data['vulnerabilityAlertHour'] ?? 8,
      lastRiskHourCalculation:
          (data['lastRiskHourCalculation'] as Timestamp?)?.toDate(),
      lastVulnerabilityCalculation:
          (data['lastVulnerabilityCalculation'] as Timestamp?)?.toDate(),
      lastAlertSent: (data['lastAlertSent'] as Timestamp?)?.toDate(),
      lastAlertType: data['lastAlertType'] as String?,
      hasPermissionDeniedBannerShown:
          data['hasPermissionDeniedBannerShown'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'isHighRiskHourEnabled': isHighRiskHourEnabled,
      'isStreakVulnerabilityEnabled': isStreakVulnerabilityEnabled,
      'lastCalculatedRiskHour': lastCalculatedRiskHour,
      'lastCalculatedVulnerableWeekday': lastCalculatedVulnerableWeekday,
      'vulnerabilityAlertHour': vulnerabilityAlertHour,
      'lastRiskHourCalculation': lastRiskHourCalculation != null
          ? Timestamp.fromDate(lastRiskHourCalculation!)
          : null,
      'lastVulnerabilityCalculation': lastVulnerabilityCalculation != null
          ? Timestamp.fromDate(lastVulnerabilityCalculation!)
          : null,
      'lastAlertSent':
          lastAlertSent != null ? Timestamp.fromDate(lastAlertSent!) : null,
      'lastAlertType': lastAlertType,
      'hasPermissionDeniedBannerShown': hasPermissionDeniedBannerShown,
    };
  }

  SmartAlertSettings copyWith({
    bool? isHighRiskHourEnabled,
    bool? isStreakVulnerabilityEnabled,
    int? lastCalculatedRiskHour,
    int? lastCalculatedVulnerableWeekday,
    int? vulnerabilityAlertHour,
    DateTime? lastRiskHourCalculation,
    DateTime? lastVulnerabilityCalculation,
    DateTime? lastAlertSent,
    String? lastAlertType,
    bool? hasPermissionDeniedBannerShown,
  }) {
    return SmartAlertSettings(
      isHighRiskHourEnabled:
          isHighRiskHourEnabled ?? this.isHighRiskHourEnabled,
      isStreakVulnerabilityEnabled:
          isStreakVulnerabilityEnabled ?? this.isStreakVulnerabilityEnabled,
      lastCalculatedRiskHour:
          lastCalculatedRiskHour ?? this.lastCalculatedRiskHour,
      lastCalculatedVulnerableWeekday: lastCalculatedVulnerableWeekday ??
          this.lastCalculatedVulnerableWeekday,
      vulnerabilityAlertHour:
          vulnerabilityAlertHour ?? this.vulnerabilityAlertHour,
      lastRiskHourCalculation:
          lastRiskHourCalculation ?? this.lastRiskHourCalculation,
      lastVulnerabilityCalculation:
          lastVulnerabilityCalculation ?? this.lastVulnerabilityCalculation,
      lastAlertSent: lastAlertSent ?? this.lastAlertSent,
      lastAlertType: lastAlertType ?? this.lastAlertType,
      hasPermissionDeniedBannerShown:
          hasPermissionDeniedBannerShown ?? this.hasPermissionDeniedBannerShown,
    );
  }

  /// Check if user has enough data for high-risk hour alerts
  bool get hasEnoughDataForRiskHour => lastCalculatedRiskHour != null;

  /// Check if user has enough data for vulnerability alerts
  bool get hasEnoughDataForVulnerability =>
      lastCalculatedVulnerableWeekday != null;

  /// Check if an alert can be sent today (max 1 per day rule)
  bool canSendAlertToday() {
    if (lastAlertSent == null) return true;

    final today = DateTime.now();
    final lastAlertDay = DateTime(
      lastAlertSent!.year,
      lastAlertSent!.month,
      lastAlertSent!.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);

    return !lastAlertDay.isAtSameMomentAs(todayDay);
  }

  List<Object?> get props => [
        isHighRiskHourEnabled,
        isStreakVulnerabilityEnabled,
        lastCalculatedRiskHour,
        lastCalculatedVulnerableWeekday,
        lastRiskHourCalculation,
        lastVulnerabilityCalculation,
        lastAlertSent,
        lastAlertType,
        hasPermissionDeniedBannerShown,
      ];
}

/// Eligibility result for smart alerts
class SmartAlertEligibility {
  final bool isEligibleForRiskHour;
  final bool isEligibleForVulnerability;
  final String? riskHourReason;
  final String? vulnerabilityReason;
  final int followUpCount;
  final int weeksOfData;

  const SmartAlertEligibility({
    required this.isEligibleForRiskHour,
    required this.isEligibleForVulnerability,
    this.riskHourReason,
    this.vulnerabilityReason,
    required this.followUpCount,
    required this.weeksOfData,
  });
}
