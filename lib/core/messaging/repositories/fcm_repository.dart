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
      if (Platform.isIOS) {
        final settings = await _messaging.getNotificationSettings();

        // Check if notifications are authorized
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          final permissionSettings = await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
            criticalAlert: true,
            announcement: true,
          );

          if (permissionSettings.authorizationStatus !=
              AuthorizationStatus.authorized) {
            return null;
          }
        }

        // Try getting APNS token multiple times with delay
        String? token;
        for (int i = 0; i < 5; i++) {
          token = await _messaging.getAPNSToken();

          if (token != null) break;
          await Future.delayed(Duration(seconds: 2));
        }
        return token;
      } else {
        final settings = await _messaging.getNotificationSettings();

        final token = await _messaging.getToken();

        return token;
      }
    } catch (e, stackTrace) {
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

      await _firestore.collection('users').doc(uid).set({
        'messagingToken': token,
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
