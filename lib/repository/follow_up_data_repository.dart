import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/core/di/container.dart';
import 'package:reboot_app_3/repository/user_context.dart';

abstract class IFollowUpDataRepository {
  Future<FollowUpData> getFollowUpData();
  Stream<FollowUpData> getFollowUpDataStream();
  Future<DateTime> getResetDate();
  Future<DateTime> getStartingDate();
  Future<void> updateFollowUpData(Map data);
}

class FirebaseFollowUpDataRepository implements IFollowUpDataRepository {
  var _db;
  var _userContext;
  final _followUpDateController = StreamController<FollowUpData>();

  FirebaseFollowUpDataRepository() {
    _db = FirebaseFirestore.instance;
    _userContext = getIt.get<IUserContext>();
  }

  Stream<DocumentSnapshot> initStream() {
    final uid = _userContext.uid;
    FirebaseCrashlytics.instance.setCustomKey("uid", uid);
    return _db.collection("users").doc(uid).snapshots().asBroadcastStream();
  }

  @override
  Future<void> updateFollowUpData(Map data) async {
    final uid = _userContext.uid;
    await _db.collection("users").doc(uid).update(data);
  }

  @override
  Future<FollowUpData> getFollowUpData() async {
    final uid = _userContext.uid;
    DocumentSnapshot snapshot = await _db.collection("users").doc(uid).get();
    return FollowUpData.fromSnapshot(snapshot);
  }

  @override
  Future<DateTime> getResetDate() async {
    final uid = _userContext.uid;
    DocumentSnapshot snapshot = await _db.collection("users").doc(uid).get();

    return DateTime.parse(
        await snapshot.get('resetedDate').toDate().toString());
  }

  @override
  Future<DateTime> getStartingDate() async {
    final uid = _userContext.uid;
    DocumentSnapshot snapshot = await _db.collection("users").doc(uid).get();

    var startingDate =
        DateTime.parse(await snapshot.get('userFirstDate').toDate().toString());
    return startingDate;
  }

  @override
  Stream<FollowUpData> getFollowUpDataStream() {
    final snapshot = _db.collection("users").doc(_userContext.uid);
    snapshot.snapshots().listen((event) {
      final followUpData = FollowUpData.fromSnapshot(event);
      _followUpDateController.add(followUpData);
    });

    return _followUpDateController.stream;
  }
}
