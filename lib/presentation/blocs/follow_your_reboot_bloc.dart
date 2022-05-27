import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';
import 'package:reboot_app_3/repository/db.dart';
import 'package:rxdart/subjects.dart';

class FollowYourRebootBloc implements CustomBlocBase {
  FollowYourRebootBloc() {
    db.initStream().listen((data) => _inFirestore.add(data));
  }

  final _firestoreController = BehaviorSubject<DocumentSnapshot>();
  Stream<DocumentSnapshot> get outFirestore => _firestoreController.stream;
  Sink<DocumentSnapshot> get _inFirestore => _firestoreController.sink;

  readFollowUpData() async {
    FollowUpData data = await db.getFollowUpData();
    return data;
  }

  Future<List<Day>> getCalenderData() async {
    return await db.getCalenderData();
  }
  
  Future<int> getRelapseStreak() async {
    return await db.getRelapseStreak();
  }

  void updateFollowUpData(DocumentSnapshot doc) async {
    //await db.updateData(doc);
  }

  void deleteFollowUpData(DocumentSnapshot doc) async {
    //await db.deleteData(doc);
  }

  void createData(String name) async {
    //await db.createData(doc);
  }

  @override
  void dispose() async {
    return _firestoreController.close();
  }
}
