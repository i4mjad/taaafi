import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

class StreakRepository {
  final FirebaseFirestore _firestore;

  StreakRepository(this._firestore);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
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
}
