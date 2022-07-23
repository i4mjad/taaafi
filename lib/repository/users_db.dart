import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersDB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    return db.collection("users").doc(uid).snapshots();
  }

  Stream<DocumentSnapshot> isUserDocExist() {
    return db.collection("users").doc(uid).get().asStream();
  }
}

UsersDB userDb = UsersDB();
