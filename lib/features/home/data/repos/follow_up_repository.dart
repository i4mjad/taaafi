import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';

/// Responsible for all Firestore interactions related to followUps.
class FollowUpRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  FollowUpRepository(this._firestore, this.ref);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create a new follow-up document under `users/{uid}/followUps`.
  Future<void> createFollowUp({
    required FollowUpModel followUp,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef =
          _firestore.collection('users').doc(uid).collection('followUps').doc();
      await docRef.set(followUp.copyWith(id: docRef.id).toMap());
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Create multiple follow-up documents under `users/{uid}/followUps`.
  Future<void> createMultipleFollowUps({
    required List<FollowUpModel> followUps,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final batch = _firestore.batch();
      for (var followUp in followUps) {
        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('followUps')
            .doc();
        batch.set(docRef, followUp.copyWith(id: docRef.id).toMap());
      }
      await batch.commit();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Read a single follow-up by its ID.
  Future<FollowUpModel?> readFollowUp({
    required String followUpId,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .doc(followUpId);
      final doc = await docRef.get();
      if (doc.exists) {
        return FollowUpModel.fromDoc(doc);
      }
      return null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Read all follow-ups for the user.
  Future<List<FollowUpModel>> readAllFollowUps() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .get();
      return querySnapshot.docs
          .map((doc) => FollowUpModel.fromDoc(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Read all follow-ups for a specific date.
  Future<List<FollowUpModel>> readFollowUpsByDate(DateTime date) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .where('time',
              isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day))
          .where('time',
              isLessThan: DateTime(date.year, date.month, date.day + 1))
          .get();
      return querySnapshot.docs
          .map((doc) => FollowUpModel.fromDoc(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing follow-up.
  Future<void> updateFollowUp({
    required FollowUpModel followUp,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .doc(followUp.id);
      await docRef.update(followUp.toMap());
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Delete a single follow-up by its ID.
  Future<void> deleteFollowUp({
    required String followUpId,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .doc(followUpId);
      await docRef.delete();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Delete the entire `followUps` sub-collection for the user.
  Future<void> deleteAllFollowUps() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final collectionRef =
          _firestore.collection('users').doc(uid).collection('followUps');
      final querySnapshot = await collectionRef.get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<DateTime> getUserFirstDate() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('userFirstDate')) {
          return (data['userFirstDate'] as Timestamp).toDate();
        }
      }
      throw Exception('User first date not found');
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Calculate the total number of follow-ups for the user.
  Future<int> calculateTotalFollowUps() async {
    try {
      final followUps = await readAllFollowUps();
      return followUps.length;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<FollowUpModel>> readFollowUpsByType(FollowUpType type) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .where('type', isEqualTo: type.name)
          .get();
      return querySnapshot.docs
          .map((doc) => FollowUpModel.fromDoc(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Calculate the days without relapse.
  Future<int> calculateDaysWithoutRelapse() async {
    try {
      final userFirstDate = await getUserFirstDate();
      final relapseFollowUps = await readFollowUpsByType(FollowUpType.relapse);

      if (relapseFollowUps.isEmpty) {
        return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
      } else {
        relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
        final lastFollowUpDate = _onlyDate(relapseFollowUps.first.time);
        return DateTime.now().difference(lastFollowUpDate).inDays;
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Calculate the total days from the user's first date.
  Future<int> calculateTotalDaysFromFirstDate() async {
    try {
      final userFirstDate = await getUserFirstDate();
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// A helper function that strips the time portion from a DateTime
  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Stream<List<FollowUpModel>> watchFollowUpsByDate(DateTime date) {
    try {
      final uid = _getUserId();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .where('time', isGreaterThanOrEqualTo: startOfDay)
          .where('time', isLessThanOrEqualTo: endOfDay)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList());
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }
}
