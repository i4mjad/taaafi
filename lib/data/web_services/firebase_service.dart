import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService(this.firestore);
  FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      firestore.collection("users");

  DocumentReference getUserDocument(String uid) {
    return _usersCollection().doc(uid);
  }

  Stream streamUserData(String uid) {
    return getUserDocument(uid).snapshots();
  }

  void functionOnStream(String uid, Function callback(DocumentSnapshot sh)) {
    streamUserData(uid).listen((event) async {
      DocumentSnapshot snapshot = event;
      await callback(snapshot);
    });
  }

  void removeField(String uid, String fieldKey) {
    streamUserData(uid).listen((event) async {
      return getUserDocument(uid).update({fieldKey: FieldValue.delete()});
    });
    //
    // Future<DocumentReference> addDocument(Map data) {
    //   return ref.add(data);
    // }
    //
    // Future<void> updateDocument(Map data, String id) {
    //   return ref.doc(id).update(data);
    // }
  }
}
