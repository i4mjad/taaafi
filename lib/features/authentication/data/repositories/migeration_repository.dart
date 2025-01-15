import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migeration_repository.g.dart';

@riverpod
MigerationRepository migerationRepository(ref) {
  return MigerationRepository(
    ref.watch(firestoreInstanceProvider),
    ref.watch(firebaseAuthProvider),
    ref,
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
  Ref ref;
  MigerationRepository(this._firestore, this._auth, this.ref);

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocMap() async {
    try {
      return await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<void> bulkFollowUpsInsertion(List<FollowUpModel> followUps) async {
    final collectionRef = _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('followUps');

    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      for (var followUp in followUps) {
        var docRef = collectionRef.doc(); // Use Firebase auto-generated ID
        batch.set(docRef, followUp.toMap());
      }

      return await batch.commit();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
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
      var updatedDocument = newDocument.toFirestore();

      await docRef.set(updatedDocument, SetOptions(merge: true));
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow; // Optionally rethrow the error to handle it further up the call stack
    }
  }
}

class FCMRepository {
  FirebaseMessaging _messaging;

  FCMRepository(this._messaging);

  Future<String> getMessagingToken() async {
    if (Platform.isIOS) {
      await _messaging.getAPNSToken() as String;
    }
    return await _messaging.getToken() as String;
  }
}
