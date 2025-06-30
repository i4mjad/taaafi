import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/home/data/models/user_report.dart';

/// Repository for handling user reports data operations
class UserReportsRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  UserReportsRepository(this._firestore, this.ref);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create a new user report document in `usersReports` collection
  Future<String> createReport({
    required String reportTypeId,
    required String initialMessage,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final reportData = {
        'uid': uid,
        'time': Timestamp.fromDate(now),
        'reportTypeId': reportTypeId,
        'status': ReportStatus.pending.name,
        'initialMessage': initialMessage,
        'lastUpdated': Timestamp.fromDate(now),
        'messagesCount': 1,
      };

      final docRef =
          await _firestore.collection('usersReports').add(reportData);

      // Add the initial message to the subcollection
      await _addMessage(
        reportId: docRef.id,
        senderId: uid,
        senderRole: 'user',
        message: initialMessage,
      );

      return docRef.id;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Add a message to a report
  Future<void> addMessage({
    required String reportId,
    required String message,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      // Check if user can send messages to this report
      final report = await getReportById(reportId);
      if (report == null) throw Exception('Report not found');
      if (report.uid != uid) throw Exception('Unauthorized access to report');

      // Check if report allows new messages
      if (report.status == ReportStatus.closed ||
          report.status == ReportStatus.finalized) {
        throw Exception('Cannot add messages to closed reports');
      }

      await _addMessage(
        reportId: reportId,
        senderId: uid,
        senderRole: 'user',
        message: message,
      );

      // Update report status and last updated time
      await _firestore.collection('usersReports').doc(reportId).update({
        'status': ReportStatus.waitingForAdminResponse.name,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'messagesCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Private method to add message to subcollection
  Future<void> _addMessage({
    required String reportId,
    required String senderId,
    required String senderRole,
    required String message,
  }) async {
    final messageData = {
      'reportId': reportId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'isRead': false,
    };

    await _firestore
        .collection('usersReports')
        .doc(reportId)
        .collection('messages')
        .add(messageData);
  }

  /// Get messages for a specific report
  Future<List<ReportMessage>> getReportMessages(String reportId) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      // Verify user has access to this report
      final report = await getReportById(reportId);
      if (report == null || report.uid != uid) {
        throw Exception('Unauthorized access to report');
      }

      final querySnapshot = await _firestore
          .collection('usersReports')
          .doc(reportId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ReportMessage.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Stream of messages for a specific report
  Stream<List<ReportMessage>> watchReportMessages(String reportId) {
    final uid = _getUserId();
    if (uid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('usersReports')
        .doc(reportId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user reports for the current user
  Future<List<UserReport>> getUserReports() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final querySnapshot = await _firestore
          .collection('usersReports')
          .where('uid', isEqualTo: uid)
          .orderBy('lastUpdated', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserReport.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get a specific report by ID for the current user
  Future<UserReport?> getReportById(String reportId) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final docSnapshot =
          await _firestore.collection('usersReports').doc(reportId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final report = UserReport.fromFirestore(docSnapshot);
      // Ensure the report belongs to the current user
      if (report.uid != uid) {
        throw Exception('Unauthorized access to report');
      }

      return report;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get pending reports for the current user
  Future<List<UserReport>> getPendingReports() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final querySnapshot = await _firestore
          .collection('usersReports')
          .where('uid', isEqualTo: uid)
          .where('status',
              whereIn: ['pending', 'inProgress', 'waitingForAdminResponse'])
          .orderBy('lastUpdated', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserReport.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Stream of user reports
  Stream<List<UserReport>> watchUserReports() {
    final uid = _getUserId();
    if (uid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('usersReports')
        .where('uid', isEqualTo: uid)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserReport.fromFirestore(doc)).toList();
    });
  }

  /// Check if user has any pending reports
  Future<bool> hasPendingReports() async {
    try {
      final pendingReports = await getPendingReports();
      return pendingReports.isNotEmpty;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }

  /// Check if user should show report button (no closed/finalized reports for data issues)
  Future<bool> shouldShowReportButton() async {
    try {
      final uid = _getUserId();
      if (uid == null) return false;

      const dataErrorReportTypeId = 'AVgC6BG76LJqDaalZFvV';

      final querySnapshot = await _firestore
          .collection('usersReports')
          .where('uid', isEqualTo: uid)
          .where('reportTypeId', isEqualTo: dataErrorReportTypeId)
          .where('status', whereIn: ['closed', 'finalized'])
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return true; // Show by default if error
    }
  }

  /// Get the most recent report for the current user
  Future<UserReport?> getMostRecentReport() async {
    try {
      final reports = await getUserReports();
      return reports.isNotEmpty ? reports.first : null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  /// Check if user can submit new messages to a report
  bool canSubmitMessage(UserReport report) {
    return report.status != ReportStatus.closed &&
        report.status != ReportStatus.finalized;
  }
}
