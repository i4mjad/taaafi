import 'package:reboot_app_3/features/shared/data/models/user_report.dart';
import 'package:reboot_app_3/features/shared/data/repositories/user_reports_repository.dart';

/// Result class for report operations
class ReportResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorKey;

  const ReportResult.success(this.data)
      : isSuccess = true,
        errorKey = null;
  const ReportResult.error(this.errorKey)
      : isSuccess = false,
        data = null;
}

/// Report type constants
class ReportTypes {
  static const String dataError = 'AVgC6BG76LJqDaalZFvV';
  static const String communityFeedback = 'C5zGTSYYbS4fVOaoDaTJ';
  static const String contactUs = 'RzznaQlqM7sCUTCO4Zmw';
  static const String postReport = 'WV2Lpe4V9ajwf0NmsAwN';
  static const String commentReport = 'n8LCt8NsTfCcYh0mN0e6';
  static const String featureSuggestion = 'JYfdeI6L9Af1LUP0LhtK';
  static const String userReport = 'MhVAEnH7sCR06Rv1JV2y';
}

/// Service for handling user reports business logic
class UserReportsService {
  final UserReportsRepository _repository;

  UserReportsService(this._repository);

  /// Check if user can create a new report of the given type
  Future<bool> canCreateReport(String reportTypeId) async {
    final userReports = await getUserReports();
    final reportsOfType = userReports
        .where((report) =>
            report.reportTypeId == reportTypeId &&
            report.status != ReportStatus.closed &&
            report.status != ReportStatus.finalized)
        .toList();

    return reportsOfType.length < 2;
  }

  /// Submit a new data error report
  Future<ReportResult<String>> submitDataErrorReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.dataError,
      userMessage: userMessage,
    );
  }

  /// Submit a new community feedback report
  Future<ReportResult<String>> submitCommunityFeedbackReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.communityFeedback,
      userMessage: userMessage,
    );
  }

  /// Submit a new contact us report
  Future<ReportResult<String>> submitContactUsReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.contactUs,
      userMessage: userMessage,
    );
  }

  /// Submit a new feature suggestion report
  Future<ReportResult<String>> submitFeatureSuggestionReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.featureSuggestion,
      userMessage: userMessage,
    );
  }

  /// Submit a new post report
  Future<ReportResult<String>> submitPostReport({
    required String postId,
    required String userMessage,
  }) async {
    final relatedContent = {
      'type': 'post',
      'contentId': postId,
    };

    return await _submitReport(
      reportTypeId: ReportTypes.postReport,
      userMessage: userMessage,
      relatedContent: relatedContent,
    );
  }

  /// Submit a new comment report
  Future<ReportResult<String>> submitCommentReport({
    required String commentId,
    required String userMessage,
  }) async {
    final relatedContent = {
      'type': 'comment',
      'contentId': commentId,
    };

    return await _submitReport(
      reportTypeId: ReportTypes.commentReport,
      userMessage: userMessage,
      relatedContent: relatedContent,
    );
  }

  /// Submit a new user report
  Future<ReportResult<String>> submitUserReport({
    required String communityProfileId,
    required String userMessage,
  }) async {
    final relatedContent = {
      'type': 'user',
      'contentId': communityProfileId,
    };

    return await _submitReport(
      reportTypeId: ReportTypes.userReport,
      userMessage: userMessage,
      relatedContent: relatedContent,
    );
  }

  /// Generic method to submit a report with validation
  Future<ReportResult<String>> _submitReport({
    required String reportTypeId,
    required String userMessage,
    Map<String, dynamic>? relatedContent,
  }) async {
    if (userMessage.trim().isEmpty) {
      return const ReportResult.error('message-cannot-be-empty');
    }

    if (userMessage.length > 1500) {
      return const ReportResult.error('message-exceeds-character-limit');
    }

    // Check if user can create another report of this type
    final canCreate = await canCreateReport(reportTypeId);
    if (!canCreate) {
      return const ReportResult.error('max-active-reports-reached');
    }

    try {
      final reportId = await _repository.createReport(
        reportTypeId: reportTypeId,
        initialMessage: userMessage,
        relatedContent: relatedContent,
      );
      return ReportResult.success(reportId);
    } catch (e) {
      return const ReportResult.error('report-submission-failed');
    }
  }

  /// Add a message to an existing report
  Future<ReportResult<void>> addMessageToReport({
    required String reportId,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      return const ReportResult.error('message-cannot-be-empty');
    }

    if (message.length > 220) {
      return const ReportResult.error('message-exceeds-character-limit');
    }

    try {
      await _repository.addMessage(
        reportId: reportId,
        message: message,
      );
      return const ReportResult.success(null);
    } catch (e) {
      return const ReportResult.error('report-submission-failed');
    }
  }

  /// Get all user reports
  Future<List<UserReport>> getUserReports() async {
    return await _repository.getUserReports();
  }

  /// Get a specific report by ID
  Future<UserReport?> getReportById(String reportId) async {
    return await _repository.getReportById(reportId);
  }

  /// Get messages for a specific report
  Future<List<ReportMessage>> getReportMessages(String reportId) async {
    return await _repository.getReportMessages(reportId);
  }

  /// Stream of messages for a specific report
  Stream<List<ReportMessage>> watchReportMessages(String reportId) {
    return _repository.watchReportMessages(reportId);
  }

  /// Stream of user reports
  Stream<List<UserReport>> watchUserReports() {
    return _repository.watchUserReports();
  }

  /// Check if user has any pending reports
  Future<bool> hasPendingReports() async {
    return await _repository.hasPendingReports();
  }

  /// Check if user should show report button
  Future<bool> shouldShowReportButton() async {
    return await _repository.shouldShowReportButton();
  }

  /// Get the most recent report
  Future<UserReport?> getMostRecentReportOfTypeDataIssue() async {
    return await _repository.getMostRecentReportOfTypeDataIssue();
  }

  /// Check if user can submit new messages to a report
  bool canSubmitMessage(UserReport report) {
    return _repository.canSubmitMessage(report);
  }

  /// Get pending reports
  Future<List<UserReport>> getPendingReports() async {
    return await _repository.getPendingReports();
  }

  /// Get status display text for a report
  String getStatusDisplayKey(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'in-progress';
      case ReportStatus.waitingForAdminResponse:
        return 'waiting-for-admin-response';
      case ReportStatus.closed:
        return 'closed';
      case ReportStatus.finalized:
        return 'finalized';
    }
  }

  /// Check if report allows new user messages
  bool allowsUserMessages(UserReport report) {
    return report.status != ReportStatus.closed &&
        report.status != ReportStatus.finalized &&
        report.status != ReportStatus.waitingForAdminResponse;
  }
}
