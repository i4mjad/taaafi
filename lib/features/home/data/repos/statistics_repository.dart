import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Responsible for all Firestore interactions related to followUps.
class StatisticsRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  StatisticsRepository(this._firestore, this.ref);

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
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .doc(followUp.id);
      await docRef.set(followUp.toMap());
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

  /// Calculate the days without relapse.
  Future<int> calculateDaysWithoutRelapse() async {
    try {
      final userFirstDate = await getUserFirstDate();
      final allFollowUps = await readAllFollowUps();
      final relapseFollowUps = allFollowUps
          .where((followUp) => followUp.type == FollowUpType.relapse)
          .toList();

      int daysWithoutRelapses = 0;
      DateTime currentDate = _onlyDate(userFirstDate);

      while (currentDate.isBefore(DateTime.now())) {
        final hasRelapse = relapseFollowUps
            .any((followUp) => _onlyDate(followUp.time) == currentDate);
        if (!hasRelapse) {
          daysWithoutRelapses++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      return daysWithoutRelapses;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Calculate the number of days from the first date until today that do not have any follow-up of type relapse.
  Future<int> calculateDaysWithoutRelapses() async {
    try {
      final userFirstDate = await getUserFirstDate();
      final allFollowUps = await readAllFollowUps();
      final relapseFollowUps = allFollowUps
          .where((followUp) => followUp.type == FollowUpType.relapse)
          .toList();

      int daysWithoutRelapses = 0;
      DateTime currentDate = _onlyDate(userFirstDate);

      while (currentDate.isBefore(DateTime.now())) {
        final hasRelapse = relapseFollowUps
            .any((followUp) => _onlyDate(followUp.time) == currentDate);
        if (!hasRelapse) {
          daysWithoutRelapses++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      return daysWithoutRelapses;
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

  /// Calculate the total days from the user's first date.
  Future<int> getRelapsesInLast30Days() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      final relapses = await readFollowUpsByType(FollowUpType.relapse);

      return relapses
          .where((followUp) => followUp.time.isAfter(thirtyDaysAgo))
          .length;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// A helper function that strips the time portion from a DateTime
  /// so that only the date is used (year-month-day).
  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
