import '../data/models/warning.dart';
import '../data/repositories/warning_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clean_warning_service.g.dart';

/// Clean warning service that delegates to repository (business logic layer)
class CleanWarningService {
  final WarningRepository _repository;

  CleanWarningService(this._repository);

  // ==================== USER WARNING QUERIES ====================

  /// Get all warnings for a user
  Future<List<Warning>> getUserWarnings(String userId) async {
    return await _repository.getUserWarnings(userId);
  }

  /// Get current user warnings
  Future<List<Warning>> getCurrentUserWarnings() async {
    return await _repository.getCurrentUserWarnings();
  }

  /// Get high priority warnings for user
  Future<List<Warning>> getHighPriorityWarnings(String userId) async {
    return await _repository.getHighPriorityWarnings(userId);
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getCurrentUserHighPriorityWarnings() async {
    return await _repository.getCurrentUserHighPriorityWarnings();
  }

  /// Get warnings by severity
  Future<List<Warning>> getWarningsBySeverity(
      String userId, WarningSeverity severity) async {
    return await _repository.getWarningsBySeverity(userId, severity);
  }

  // ==================== WARNING CHECKS ====================

  /// Check if user has critical warnings
  Future<bool> hasCriticalWarnings(String userId) async {
    return await _repository.hasCriticalWarnings(userId);
  }

  /// Check if current user has critical warnings
  Future<bool> currentUserHasCriticalWarnings() async {
    final warnings = await getCurrentUserWarnings();
    return warnings
        .any((warning) => warning.severity == WarningSeverity.critical);
  }

  /// Check if user has high priority warnings
  Future<bool> hasHighPriorityWarnings(String userId) async {
    final warnings = await getHighPriorityWarnings(userId);
    return warnings.isNotEmpty;
  }

  // ==================== DEVICE TRACKING ====================

  /// Get warnings by device IDs
  Future<List<Warning>> getWarningsByDeviceIds(List<String> deviceIds) async {
    return await _repository.getWarningsByDeviceIds(deviceIds);
  }

  /// Get warning history
  Future<List<Warning>> getWarningHistory(String userId,
      {int limit = 20}) async {
    return await _repository.getWarningHistory(userId, limit: limit);
  }

  // ==================== REAL-TIME DATA ====================

  /// Stream of user warnings
  Stream<List<Warning>> watchUserWarnings(String userId) {
    return _repository.watchUserWarnings(userId);
  }

  /// Stream of current user warnings
  Stream<List<Warning>> watchCurrentUserWarnings() {
    return _repository.watchCurrentUserWarnings();
  }

  // ==================== BUSINESS LOGIC HELPERS ====================

  /// Calculate warning status summary for user
  Future<WarningStatusSummary> getWarningStatusSummary(String userId) async {
    final warnings = await getUserWarnings(userId);

    final criticalWarnings =
        warnings.where((w) => w.severity == WarningSeverity.critical).toList();
    final highWarnings =
        warnings.where((w) => w.severity == WarningSeverity.high).toList();
    final mediumWarnings =
        warnings.where((w) => w.severity == WarningSeverity.medium).toList();
    final lowWarnings =
        warnings.where((w) => w.severity == WarningSeverity.low).toList();

    return WarningStatusSummary(
      totalWarnings: warnings.length,
      criticalCount: criticalWarnings.length,
      highCount: highWarnings.length,
      mediumCount: mediumWarnings.length,
      lowCount: lowWarnings.length,
    );
  }

  /// Check if user's warning level requires intervention
  Future<bool> requiresIntervention(String userId) async {
    final summary = await getWarningStatusSummary(userId);

    // Business rule: Critical warnings or more than 3 high warnings require intervention
    return summary.criticalCount > 0 || summary.highCount > 3;
  }

  // ==================== WARNING ACTIONS ====================

  /// Mark warning as read
  Future<void> markWarningAsRead(String warningId) async {
    return await _repository.markWarningAsRead(warningId);
  }
}

/// Business logic data class for warning status
class WarningStatusSummary {
  final int totalWarnings;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;

  const WarningStatusSummary({
    required this.totalWarnings,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
  });

  bool get hasCriticalWarnings => criticalCount > 0;
  bool get hasHighPriorityWarnings => criticalCount > 0 || highCount > 0;
  bool get isInGoodStanding => totalWarnings == 0;
  int get highPriorityCount => criticalCount + highCount;
}

// ==================== PROVIDERS ====================

@riverpod
CleanWarningService cleanWarningService(CleanWarningServiceRef ref) {
  final repository = ref.watch(warningRepositoryProvider);
  return CleanWarningService(repository);
}
