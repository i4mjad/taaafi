import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/shared/application/user_reports_service.dart';
import 'package:reboot_app_3/features/shared/data/models/user_report.dart';
import 'package:reboot_app_3/features/shared/data/repositories/user_reports_repository.dart';

part 'user_reports_notifier.g.dart';

@riverpod
class UserReportsNotifier extends _$UserReportsNotifier {
  UserReportsService get service => ref.read(userReportsServiceProvider);

  @override
  FutureOr<List<UserReport>> build() async {
    return await service.getUserReports();
  }

  /// Submit a new data error report
  Future<String> submitDataErrorReport({
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitDataErrorReport(
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new community feedback report
  Future<String> submitCommunityFeedbackReport({
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitCommunityFeedbackReport(
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new contact us report
  Future<String> submitContactUsReport({
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitContactUsReport(
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new feature suggestion report
  Future<String> submitFeatureSuggestionReport({
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitFeatureSuggestionReport(
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new post report
  Future<String> submitPostReport({
    required String postId,
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitPostReport(
        postId: postId,
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new comment report
  Future<String> submitCommentReport({
    required String commentId,
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitCommentReport(
        commentId: commentId,
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new user report
  Future<String> submitUserReport({
    required String communityProfileId,
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitUserReport(
        communityProfileId: communityProfileId,
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new message report
  Future<String> submitMessageReport({
    required String messageId,
    required String groupId,
    required String userMessage,
    String? messageSender,
    String? messageContent,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitMessageReport(
        messageId: messageId,
        groupId: groupId,
        userMessage: userMessage,
        messageSender: messageSender,
        messageContent: messageContent,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Submit a new group update report
  Future<String> submitGroupUpdateReport({
    required String updateId,
    required String userMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await service.submitGroupUpdateReport(
        updateId: updateId,
        userMessage: userMessage,
      );

      if (result.isSuccess) {
        // Refresh the reports after submission
        state = AsyncValue.data(await service.getUserReports());
        return result.data ?? '';
      } else {
        final errorKey = result.errorKey ?? 'report-submission-failed';
        state = AsyncValue.error(errorKey, StackTrace.current);
        throw Exception(errorKey);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Add a message to an existing report
  Future<void> addMessageToReport({
    required String reportId,
    required String message,
  }) async {
    try {
      final result = await service.addMessageToReport(
        reportId: reportId,
        message: message,
      );

      if (!result.isSuccess) {
        throw Exception(result.errorKey ?? 'report-submission-failed');
      }

      // Refresh the reports after adding message
      state = AsyncValue.data(await service.getUserReports());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Get a specific report by ID
  Future<UserReport?> getReportById(String reportId) async {
    try {
      return await service.getReportById(reportId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Refresh the reports list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await service.getUserReports());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Check if user has any pending reports
  Future<bool> hasPendingReports() async {
    try {
      return await service.hasPendingReports();
    } catch (e) {
      return false;
    }
  }

  /// Check if user should see the report button
  Future<bool> shouldShowReportButton() async {
    try {
      return await service.shouldShowReportButton();
    } catch (e) {
      return true;
    }
  }

  /// Get the most recent report if it exists
  Future<UserReport?> getMostRecentReportOfTypeDataIssue() async {
    try {
      return await service.getMostRecentReportOfTypeDataIssue();
    } catch (e) {
      return null;
    }
  }

  /// Check if user can submit new messages to a report
  bool canSubmitMessage(UserReport report) {
    return service.canSubmitMessage(report);
  }

  /// Get pending reports
  Future<List<UserReport>> getPendingReports() async {
    try {
      return await service.getPendingReports();
    } catch (e) {
      return [];
    }
  }
}

/// Provider for report messages
@riverpod
Future<List<ReportMessage>> reportMessages(Ref ref, String reportId) async {
  final service = ref.watch(userReportsServiceProvider);
  return await service.getReportMessages(reportId);
}

/// Provider for UserReportsService
@riverpod
UserReportsService userReportsService(Ref ref) {
  final repository = ref.watch(userReportsRepositoryProvider);
  return UserReportsService(repository);
}

/// Provider for UserReportsRepository
@riverpod
UserReportsRepository userReportsRepository(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  return UserReportsRepository(firestore, ref);
}

/// Provider for watching user reports stream
@riverpod
Stream<List<UserReport>> userReportsStream(Ref ref) {
  final service = ref.watch(userReportsServiceProvider);
  return service.watchUserReports();
}

/// Provider for watching report messages stream
@riverpod
Stream<List<ReportMessage>> reportMessagesStream(Ref ref, String reportId) {
  final service = ref.watch(userReportsServiceProvider);
  return service.watchReportMessages(reportId);
}

/// Provider for checking if report button should be shown
@riverpod
Future<bool> shouldShowReportButton(Ref ref) async {
  final service = ref.watch(userReportsServiceProvider);
  return await service.shouldShowReportButton();
}

/// Provider for hiding/showing the data error container
final hideDataErrorContainerProvider = StateProvider<bool>((ref) => false);
