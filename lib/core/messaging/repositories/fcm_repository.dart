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
    print('Getting messaging token...');
    try {
      if (Platform.isIOS) {
        print('Platform is iOS, getting APNS token...');
        final token = await _messaging.getAPNSToken();
        print('Got APNS token: $token');
        return token;
      } else {
        print('Platform is Android, getting FCM token...');
        final token = await _messaging.getToken();
        print('Got FCM token: $token');
        return token;
      }
    } catch (e) {
      print('Error getting messaging token: $e');
      return null;
    }
  }

  Future<void> updateUserMessagingToken() async {
    print('Starting to update user messaging token...');
    try {
      print('Getting messaging token...');
      final token = await getMessagingToken();
      if (token == null) {
        print('Failed to get messaging token');
        throw Exception('Failed to get messaging token');
      }
      print('Successfully got messaging token: $token');

      print('Getting current user ID...');
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('No user signed in');
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'User must be signed in to update messaging token',
        );
      }
      print('Got user ID: $uid');

      print('Updating Firestore document...');
      await _firestore.collection('users').doc(uid).set({
        'messagingToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));
      print('Successfully updated messaging token in Firestore');
    } catch (e) {
      print('Error updating messaging token: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FCMRepository fcmRepository(FcmRepositoryRef ref) {
  print('Creating new FCMRepository instance');
  return FCMRepository(
    ref.watch(fcmProvider),
    ref.watch(fcmAuthProvider),
    ref.watch(fcmFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
FirebaseMessaging fcm(FcmRef ref) {
  print('Getting FirebaseMessaging instance');
  return FirebaseMessaging.instance;
}

@Riverpod(keepAlive: true)
FirebaseAuth fcmAuth(FcmAuthRef ref) {
  print('Getting FirebaseAuth instance');
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
FirebaseFirestore fcmFirestore(FcmFirestoreRef ref) {
  print('Getting FirebaseFirestore instance');
  return FirebaseFirestore.instance;
}
