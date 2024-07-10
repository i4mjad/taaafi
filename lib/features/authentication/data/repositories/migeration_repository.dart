import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/FollowUp.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
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

  Future<void> bulkFollowUpsInsertion(List<FollowUp> followUps) async {
    final collectionRef = _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('followUps');

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var followUp in followUps) {
      var docRef = collectionRef.doc(followUp.id);
      batch.set(docRef, followUp.toMap());
    }

    return await batch.commit();
  }

  Future<void> updateUserDocument(UserDocument newDocument) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Handle the case where the user is not authenticated
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'User must be signed in to update their document.',
      );
    }

    final docRef = _firestore.collection('users').doc(uid);

    try {
      await docRef.update(newDocument.toFirestore());
    } catch (e) {
      // Handle potential errors
      print('Failed to update user document: $e');
      rethrow; // Optionally rethrow the error to handle it further up the call stack
    }
  }
}

class FCMRepository {
  FirebaseMessaging _messaging;

  FCMRepository(this._messaging);

  Future<String> getMessagingToken() async {
    return await _messaging.getToken() as String;
  }
}
