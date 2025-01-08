import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_repository.g.dart';

class FCMRepository {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FCMRepository(this._messaging, this._auth, this._firestore);

  Future<String?> getMessagingToken() async {
    try {
      if (Platform.isIOS) {
        return await _messaging.getAPNSToken();
      } else {
        return await _messaging.getToken();
      }
    } catch (e) {
      print('Error getting messaging token: $e');
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

      await _firestore.collection('users').doc(uid).set({
        'messagingToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating messaging token: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FCMRepository fcmRepository(FcmRepositoryRef ref) {
  return FCMRepository(ref.watch(fcmProvider), ref.watch(fcmAuthProvider),
      ref.watch(fcmFirestoreProvider));
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
