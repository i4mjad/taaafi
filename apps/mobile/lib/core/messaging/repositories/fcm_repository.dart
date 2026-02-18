import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_repository.g.dart';

class FirebaseMessagingRepository {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseMessagingRepository(this._messaging, this._auth, this._firestore);

  Future<String?> getMessagingToken() async {
    print('🔑 FCM REPO (App Init): Getting messaging token...');
    print('🔑 FCM REPO (App Init): Platform: ${Platform.isIOS ? "iOS" : "Android"}');
    
    // On iOS, try to get APNS token first (but don't fail if not available)
    if (Platform.isIOS) {
      try {
        print('🔑 FCM REPO (App Init): iOS detected, requesting APNS token...');
        final apnsToken = await _messaging.getAPNSToken();
        print('🔑 FCM REPO (App Init): APNS Token: ${apnsToken ?? "null"}');
      } catch (e) {
        // APNS token not available yet - this is OK, FCM token might still work
        print('⚠️ FCM REPO (App Init): APNS token not available (this is OK): $e');
      }
    }
    
    // Get FCM token - this should work after APNS token is set
    try {
      print('🔑 FCM REPO (App Init): Getting FCM token from Firebase...');
      final token = await _messaging.getToken();
      
      if (token == null) {
        print('⚠️ FCM REPO (App Init): Token is NULL');
        return null;
      }
      
      print('✅ FCM REPO (App Init): Token retrieved successfully: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('❌ FCM REPO (App Init) ERROR: Failed to get FCM token: $e');
      
      // On iOS, if APNS token isn't available yet, return null instead of throwing
      // The token will be updated later when APNS becomes available
      if (Platform.isIOS && e.toString().contains('apns-token-not-set')) {
        print('ℹ️ FCM REPO (App Init): APNS not ready on iOS, will retry later');
        return null;
      }
      
      throw Exception('Failed to get messaging token: $e');
    }
  }

  Future<void> updateUserMessagingToken() async {
    try {
      print('=== UPDATE FCM TOKEN START ===');
      
      final token = await getMessagingToken();
      if (token == null) {
        print('⚠️ FCM TOKEN: Token is null (APNS may not be ready on iOS)');
        print('ℹ️ FCM TOKEN: Skipping update, will retry when token is available');
        print('=== UPDATE FCM TOKEN END (Skipped) ===');
        return; // Don't fail, just skip - token will be updated later
      }
      
      print('✅ FCM TOKEN: Got token: ${token.substring(0, 20)}...');

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('❌ FCM TOKEN: No user signed in');
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'User must be signed in to update messaging token',
        );
      }
      
      print('👤 FCM TOKEN: User ID: $uid');

      // Check if user document exists
      final docRef = await _firestore.collection('users').doc(uid).get();
      if (!docRef.exists) {
        print('⚠️ FCM TOKEN: User document does not exist, skipping token update');
        return; // Skip updating if document doesn't exist
      }
      
      print('📄 FCM TOKEN: User document exists, updating token...');

      await _firestore.collection('users').doc(uid).set({
        'messagingToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));
      
      print('✅ FCM TOKEN: Successfully updated messaging token in Firestore');
      print('=== UPDATE FCM TOKEN END ===');
    } catch (e) {
      print('❌ FCM TOKEN ERROR: $e');
      // Don't rethrow - allow app to continue even if token update fails
      // Token will be updated on next app launch or token refresh
    }
  }
}

@Riverpod(keepAlive: true)
FirebaseMessagingRepository fcmRepository(Ref ref) {
  return FirebaseMessagingRepository(
    ref.watch(fcmProvider),
    ref.watch(fcmAuthProvider),
    ref.watch(fcmFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
FirebaseMessaging fcm(Ref ref) {
  return FirebaseMessaging.instance;
}

@Riverpod(keepAlive: true)
FirebaseAuth fcmAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
FirebaseFirestore fcmFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}
