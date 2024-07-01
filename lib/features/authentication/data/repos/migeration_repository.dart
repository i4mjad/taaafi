import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migeration_repository.g.dart';

@riverpod
MigerationRepository migerationRepository(ref) {
  return MigerationRepository(
    ref.watch(firestoreInstanceProvider),
    ref.watch(firebaseAuthProvider),
  );
}

@riverpod
FCMRepository fcmRepository(ref) {
  return FCMRepository(
    ref.watch(messagingInstanceProvider),
  );
}

class MigerationRepository {
  FirebaseFirestore _firestore;
  FirebaseAuth _auth;
  MigerationRepository(this._firestore, this._auth);

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocMap() async {
    return await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get();
  }
}

class FCMRepository {
  FirebaseMessaging _messaging;

  FCMRepository(this._messaging);

  Future<String> getMessagingToken() async {
    return await _messaging.getToken() as String;
  }
}
