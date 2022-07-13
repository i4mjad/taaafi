import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/bloc_provider.dart';

import 'package:reboot_app_3/repository/db.dart';

class NewUserBloc implements CustomBlocBase {
  NewUserBloc() {
    userDB.initStream().listen((data) => _inFirestore.add(data));
  }
  final _firestoreController = StreamController<DocumentSnapshot>();
  Stream<DocumentSnapshot> get outFirestore => _firestoreController.stream;
  Sink<DocumentSnapshot> get _inFirestore => _firestoreController.sink;

  @override
  void dispose() async {
    return _firestoreController.close();
  }

  Stream<bool> isUserDocExist() {
    return db.isUserDocExist().asStream();
  }
}

class UserDB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    return db.collection("users").doc(uid).snapshots();
  }

  Future<bool> isUserDocExist() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return await snapshot.exists;
  }
}

UserDB userDB = UserDB();
