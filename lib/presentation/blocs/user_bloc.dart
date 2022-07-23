import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/repository/users_db.dart';

class UserBloc implements CustomBlocBase {
  UserBloc() {
    userDb.initStream().listen((data) => _inFirestore.add(data));
  }
  final _firestoreController = StreamController<DocumentSnapshot>();
  Stream<DocumentSnapshot> get outFirestore => _firestoreController.stream;
  Sink<DocumentSnapshot> get _inFirestore => _firestoreController.sink;

  @override
  void dispose() async {
    return _firestoreController.close();
  }

  Stream<DocumentSnapshot> UserDoc() {
    return userDb.isUserDocExist();
  }
}
