import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import '../models/warning.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'warning_repository.g.dart';

/// Repository responsible for warning-related Firestore operations
class WarningRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref ref;

  WarningRepository(this._firestore, this._auth, this.ref);

  String? _getUserId() => _auth.currentUser?.uid;

  /// Get all active warnings for a specific user
  Future<List<Warning>> getUserWarnings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('warnings')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get active warnings for the current user
  Future<List<Warning>> getCurrentUserWarnings() async {
    try {
      final userId = _getUserId();
      if (userId == null) return [];
      return await getUserWarnings(userId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get high priority warnings for a specific user
  Future<List<Warning>> getHighPriorityWarnings(String userId) async {
    try {
      final warnings = await getUserWarnings(userId);
      return warnings
          .where((warning) =>
              warning.severity == WarningSeverity.high ||
              warning.severity == WarningSeverity.critical)
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getCurrentUserHighPriorityWarnings() async {
    try {
      final userId = _getUserId();
      if (userId == null) return [];
      return await getHighPriorityWarnings(userId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get warnings by severity level
  Future<List<Warning>> getWarningsBySeverity(
      String userId, WarningSeverity severity) async {
    try {
      final querySnapshot = await _firestore
          .collection('warnings')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('severity', isEqualTo: severity.name)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get warnings by device IDs (for device tracking)
  Future<List<Warning>> getWarningsByDeviceIds(List<String> deviceIds) async {
    try {
      if (deviceIds.isEmpty) return [];

      // Limit to 10 device IDs for Firestore query limitations
      final limitedDeviceIds = deviceIds.take(10).toList();

      final querySnapshot = await _firestore
          .collection('warnings')
          .where('deviceIds', arrayContainsAny: limitedDeviceIds)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Check if user has critical warnings
  Future<bool> hasCriticalWarnings(String userId) async {
    try {
      final warnings = await getUserWarnings(userId);
      return warnings
          .any((warning) => warning.severity == WarningSeverity.critical);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false; // Fail safe
    }
  }

  /// Stream of user warnings for real-time updates
  Stream<List<Warning>> watchUserWarnings(String userId) {
    return _firestore
        .collection('warnings')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Warning.fromFirestore(doc)).toList();
    });
  }

  /// Stream of current user warnings
  Stream<List<Warning>> watchCurrentUserWarnings() {
    final userId = _getUserId();
    if (userId == null) {
      return Stream.value([]);
    }
    return watchUserWarnings(userId);
  }

  /// Get warning history for violations (admin panel)
  Future<List<Warning>> getWarningHistory(String userId,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('warnings')
          .where('userId', isEqualTo: userId)
          .orderBy('issuedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Mark warning as read (if needed)
  Future<void> markWarningAsRead(String warningId) async {
    try {
      await _firestore
          .collection('warnings')
          .doc(warningId)
          .update({'isRead': true});
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }
}

// ==================== PROVIDERS ====================

@riverpod
WarningRepository warningRepository(WarningRepositoryRef ref) {
  return WarningRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}
