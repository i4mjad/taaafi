import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usage_repository.g.dart';

class UsageRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  UsageRepository(this._firestore, this._ref);

  String? _getUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Save a daily usage summary to Firestore.
  Future<void> saveUsageSummary(UsageSummary summary) async {
    try {
      final uid = _getUserId();
      if (uid == null) return;

      final dateKey = _dateFormat.format(summary.date);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('usageSummaries')
          .doc(dateKey)
          .set(summary.toJson(), SetOptions(merge: true));
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  /// Get today's usage summary from Firestore (cached version).
  Future<UsageSummary?> getTodaySummary() async {
    try {
      final uid = _getUserId();
      if (uid == null) return null;

      final dateKey = _dateFormat.format(DateTime.now());
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('usageSummaries')
          .doc(dateKey)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return UsageSummary.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  /// Get usage summaries for a date range (premium: full history).
  Future<List<UsageSummary>> getSummariesInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final uid = _getUserId();
      if (uid == null) return [];

      final startKey = _dateFormat.format(start);
      final endKey = _dateFormat.format(end);

      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('usageSummaries')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
          .orderBy(FieldPath.documentId)
          .get();

      return query.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => UsageSummary.fromJson(doc.data()))
          .toList();
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
      return [];
    }
  }

  /// Get this month's summaries (free tier).
  Future<List<UsageSummary>> getCurrentMonthSummaries() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return getSummariesInRange(monthStart, now);
  }
}

@Riverpod(keepAlive: true)
UsageRepository usageRepository(Ref ref) {
  return UsageRepository(FirebaseFirestore.instance, ref);
}
