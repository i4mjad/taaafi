/// Result of a bulk operation on group members
/// Sprint 2 - Feature 2.2: Bulk Member Management
class BulkOperationResult {
  final int successCount;
  final int failureCount;
  final List<String> failedCpIds;
  final List<String> failureReasons;
  final bool allSucceeded;

  const BulkOperationResult({
    required this.successCount,
    required this.failureCount,
    required this.failedCpIds,
    required this.failureReasons,
  }) : allSucceeded = failureCount == 0;

  /// Create a successful result with no failures
  factory BulkOperationResult.success(int count) {
    return BulkOperationResult(
      successCount: count,
      failureCount: 0,
      failedCpIds: [],
      failureReasons: [],
    );
  }

  /// Create a failed result with no successes
  factory BulkOperationResult.failure(List<String> cpIds, String reason) {
    return BulkOperationResult(
      successCount: 0,
      failureCount: cpIds.length,
      failedCpIds: cpIds,
      failureReasons: List.filled(cpIds.length, reason),
    );
  }

  /// Create a partial result with both successes and failures
  factory BulkOperationResult.partial({
    required int successCount,
    required List<String> failedCpIds,
    required List<String> failureReasons,
  }) {
    return BulkOperationResult(
      successCount: successCount,
      failureCount: failedCpIds.length,
      failedCpIds: failedCpIds,
      failureReasons: failureReasons,
    );
  }

  int get totalCount => successCount + failureCount;

  double get successRate =>
      totalCount > 0 ? successCount / totalCount : 0.0;

  bool get hasFailures => failureCount > 0;

  @override
  String toString() {
    return 'BulkOperationResult(success: $successCount, failed: $failureCount, total: $totalCount)';
  }
}

