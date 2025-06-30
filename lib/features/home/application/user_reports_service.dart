import 'package:reboot_app_3/features/home/data/models/user_report.dart';
import 'package:reboot_app_3/features/home/data/repos/user_reports_repository.dart';

/// Report type constants
class ReportTypes {
  static const String dataError = 'AVgC6BG76LJqDaalZFvV';
  static const String communityFeedback = 'C5zGTSYYbS4fVOaoDaTJ';
  static const String contactUs = 'RzznaQlqM7sCUTCO4Zmw';
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
  Future<String> submitDataErrorReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.dataError,
      userMessage: userMessage,
    );
  }

  /// Submit a new community feedback report
  Future<String> submitCommunityFeedbackReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.communityFeedback,
      userMessage: userMessage,
    );
  }

  /// Submit a new contact us report
  Future<String> submitContactUsReport({
    required String userMessage,
  }) async {
    return await _submitReport(
      reportTypeId: ReportTypes.contactUs,
      userMessage: userMessage,
    );
  }

  /// Generic method to submit a report with validation
  Future<String> _submitReport({
    required String reportTypeId,
    required String userMessage,
  }) async {
    if (userMessage.trim().isEmpty) {
      throw Exception('User message cannot be empty');
    }

    if (userMessage.length > 220) {
      throw Exception('Message exceeds 220 characters');
    }

    // Check if user can create another report of this type
    final canCreate = await canCreateReport(reportTypeId);
    if (!canCreate) {
      throw Exception(
          'You already have 2 active reports of this type. Please wait for them to be resolved.');
    }

    return await _repository.createReport(
      reportTypeId: reportTypeId,
      initialMessage: userMessage,
    );
  }

  /// Add a message to an existing report
  Future<void> addMessageToReport({
    required String reportId,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    if (message.length > 220) {
      throw Exception('Message exceeds 220 characters');
    }

    await _repository.addMessage(
      reportId: reportId,
      message: message,
    );
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
  Future<UserReport?> getMostRecentReport() async {
    return await _repository.getMostRecentReport();
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
