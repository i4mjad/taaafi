import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';

class DB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    return db.collection("users").doc(uid).snapshots();
  }

  Future<FollowUpData> getFollowUpData() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return FollowUpData.fromSnapshot(snapshot);
  }
}

DB db = DB();
