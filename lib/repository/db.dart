import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';

class DB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    FirebaseCrashlytics.instance.setCustomKey("uid", uid);
    return db.collection("users").doc(uid).snapshots().asBroadcastStream();
  }

  Future<FollowUpData> getFollowUpData() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();
    return FollowUpData.fromSnapshot(snapshot);
  }

  Future<DateTime> getResetDate() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return DateTime.parse(
        await snapshot.get('resetedDate').toDate().toString());
  }

  Future<DateTime> getStartingDate() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return DateTime.parse(
        await snapshot.get('userFirstDate').toDate().toString());
  }
}


