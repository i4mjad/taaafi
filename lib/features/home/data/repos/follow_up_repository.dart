import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up.dart';
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
        .doc(followUp.id);
    await docRef.set(followUp.toMap());
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

  /// Read follow-ups by type.
  Future<List<FollowUpModel>> readFollowUpsByType(FollowUpType type) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .where('type', isEqualTo: type.toString())
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
}
