import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Responsible for all Firestore interactions related to followUps.
class FollowUpRepository {
  final FirebaseFirestore _firestore;

  FollowUpRepository(this._firestore);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create a new follow-up document under `users/{uid}/followUps`.
  Future<void> createFollowUp({
    required FollowUpModel followUp,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .doc(); // Generate ID by Firestore
    await docRef.set(followUp.copyWith(id: docRef.id).toMap());
  }

  /// Create multiple follow-up documents under `users/{uid}/followUps`.
  Future<void> createMultipleFollowUps({
    required List<FollowUpModel> followUps,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final batch = _firestore.batch();
    for (var followUp in followUps) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .doc(); // Generate ID by Firestore
      batch.set(docRef, followUp.copyWith(id: docRef.id).toMap());
    }
    await batch.commit();
  }

  /// Read a single follow-up by its ID.
  Future<FollowUpModel?> readFollowUp({
    required String followUpId,
  }) async {
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
  }

  /// Read all follow-ups for the user.
  Future<List<FollowUpModel>> readAllFollowUps() async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .get();
    return querySnapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  /// Update an existing follow-up.
  Future<void> updateFollowUp({
    required FollowUpModel followUp,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .doc(followUp.id);
    await docRef.update(followUp.toMap());
  }

  /// Delete a single follow-up by its ID.
  Future<void> deleteFollowUp({
    required String followUpId,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .doc(followUpId);
    await docRef.delete();
  }

  /// Delete the entire `followUps` sub-collection for the user.
  Future<void> deleteAllFollowUps() async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final collectionRef =
        _firestore.collection('users').doc(uid).collection('followUps');
    final querySnapshot = await collectionRef.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<DateTime> getUserFirstDate() async {
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
  }

  /// Calculate the total number of follow-ups for the user.
  Future<int> calculateTotalFollowUps() async {
    final followUps = await readAllFollowUps();
    return followUps.length;
  }

  Future<List<FollowUpModel>> readFollowUpsByType(FollowUpType type) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .where('type', isEqualTo: type.name)
        .get();
    return querySnapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  /// Calculate the days without relapse.
  Future<int> calculateDaysWithoutRelapse() async {
    final userFirstDate = await getUserFirstDate();
    final relapseFollowUps = await readFollowUpsByType(FollowUpType.relapse);

    if (relapseFollowUps.isEmpty) {
      return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
    } else {
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = _onlyDate(relapseFollowUps.first.time);
      return DateTime.now().difference(lastFollowUpDate).inDays;
    }
  }

  /// Calculate the total days from the user's first date.
  Future<int> calculateTotalDaysFromFirstDate() async {
    final userFirstDate = await getUserFirstDate();
    return DateTime.now().difference(_onlyDate(userFirstDate)).inDays;
  }

  /// A helper function that strips the time portion from a DateTime
  /// so that only the date is used (year-month-day).
  DateTime _onlyDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
