// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:reboot_app_3/bloc_provider.dart';

// import 'package:reboot_app_3/repository/db.dart';

// class AccountBloc implements CustomBlocBase {
//   AccountBloc() {
//     db.initStream().listen((data) => _inFirestore.add(data));
//   }
//   final _firestoreController = StreamController<DocumentSnapshot>();
//   Stream<DocumentSnapshot> get outFirestore => _firestoreController.stream;
//   Sink<DocumentSnapshot> get _inFirestore => _firestoreController.sink;

//   @override
//   void dispose() async {
//     return _firestoreController.close();
//   }

//   Future<void> createNewData(DateTime selectedDate) async {
//     return await db.createNewData(selectedDate);
//   }

//   Stream<bool> isUserDocExist() {
//     return db.isUserDocExist().asStream();
//   }

//   Future<void> deleteUserData() async{
//     return await db.deleteUserData();
//   }
// }
