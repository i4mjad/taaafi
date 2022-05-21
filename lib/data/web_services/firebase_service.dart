import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService(this.firestore, this.uid);
  FirebaseFirestore firestore;
  String uid;

  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      firestore.collection("users");

  DocumentReference getUserDocument() {
    return _usersCollection().doc(uid);
  }

  Future<void> updateUserData(String uid, String name, String email) async {
    return await getUserDocument().get().then((value) => {
          value.data(),
        });
  }

  Stream streamUserData() {
    return getUserDocument().snapshots();
  }

  void removeFieldByKey(String fieldKey) async {
    streamUserData().listen((event) async {
      return event.update({fieldKey: FieldValue.delete()});
    });
  }

  void addField(Map<String, dynamic> cake) async {
    streamUserData().listen((event) async {
      return getUserDocument()
          .set(cake, SetOptions(merge: true))
          .onError((error, stackTrace) => print(error));
    });
  }
}
