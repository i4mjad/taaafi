import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Responsible for all Firestore interactions related to calendar followUps.
class CalendarRepository {
  final FirebaseFirestore _firestore;

  CalendarRepository(this._firestore);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<List<FollowUpModel>> getFollowUps() async {
    final snapshot = await _firestore.collection('followUps').get();
    return snapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  /// Read follow-ups for a specific date range.
  Future<List<FollowUpModel>> readFollowUpsForDateRange(
      DateTime start, DateTime end) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return querySnapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  Stream<List<FollowUpModel>> followUpsStream() {
    final uid = _getUserId();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
    });
  }

  /// Read follow-ups for a set of dates.
  Future<List<FollowUpModel>> readFollowUpsForDates(
      List<DateTime> dates) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .where('time',
            whereIn: dates.map((date) => Timestamp.fromDate(date)).toList())
        .get();
    return querySnapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  /// Read follow-ups for a specific month.
  Future<List<FollowUpModel>> readFollowUpsForMonth(int year, int month) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followUps')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return querySnapshot.docs.map((doc) => FollowUpModel.fromDoc(doc)).toList();
  }

  Future<DateTime> getUserFirstDate() async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final userDoc = await _firestore.collection('users').doc(uid).get();

    final ts = userDoc.data()?['userFirstDate'] as Timestamp?;
    if (ts != null) {
      return ts.toDate();
    }
    throw Exception('User first date not found');
  }
}
