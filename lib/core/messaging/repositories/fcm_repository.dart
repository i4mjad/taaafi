import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_repository.g.dart';

class FirebaseMessagingRepository {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseMessagingRepository(this._messaging, this._auth, this._firestore);

  Future<String?> getMessagingToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      throw Exception('Failed to get messaging token: $e');
      return null;
    }
  }

  Future<void> updateUserMessagingToken() async {
    try {
      final token = await getMessagingToken();
      if (token == null) {
        throw Exception('Failed to get messaging token');
      }

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'User must be signed in to update messaging token',
        );
      }

      // Check if user document exists
      final docRef = await _firestore.collection('users').doc(uid).get();
      if (!docRef.exists) {
        return; // Skip updating if document doesn't exist
      }

      await _firestore.collection('users').doc(uid).set({
        'messagingToken': await _messaging.getToken(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FirebaseMessagingRepository fcmRepository(FcmRepositoryRef ref) {
  return FirebaseMessagingRepository(
    ref.watch(fcmProvider),
    ref.watch(fcmAuthProvider),
    ref.watch(fcmFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
FirebaseMessaging fcm(FcmRef ref) {
  return FirebaseMessaging.instance;
}

@Riverpod(keepAlive: true)
FirebaseAuth fcmAuth(FcmAuthRef ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
FirebaseFirestore fcmFirestore(FcmFirestoreRef ref) {
  return FirebaseFirestore.instance;
}
