import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/monitoring/google_analytics_client.dart';
import 'package:reboot_app_3/core/monitoring/mixpanel_analytics_client.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this.ref);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Ref ref;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> getLoggedInUser() async {
    try {
      await _auth.currentUser?.reload();
      return await _auth.currentUser;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  Future<bool> isUserDocumentExist() async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      return docRef.exists;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow; // Propagate error instead of returning false
    }
  }

  Future<void> creatUserDocuemnt(
    BuildContext context,
    User? user,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
    String messagingToken,
    String deviceId,
  ) async {
    try {
      print('=== CREATE USER DOCUMENT ===');
      
      if (user == null) {
        print('❌ CREATE DOC: User is null, aborting');
        return;
      }
      
      print('📝 CREATE DOC: Building user document...');
      print('   - UID: ${user.uid}');
      print('   - Name: $name');
      print('   - Email: ${user.email}');
      print('   - Device ID: $deviceId');
      print('   - Messaging Token: $messagingToken');
      print('   - Role: user');
      
      final userDocument = UserDocument(
        uid: user.uid,
        devicesIds: [deviceId],
        displayName: name,
        email: user.email ?? "Unknown",
        gender: gender,
        locale: locale,
        dayOfBirth: Timestamp.fromDate(dob.toUtc()),
        userFirstDate: Timestamp.fromDate(firstDate.toUtc()),
        role: "user",
        messagingToken: messagingToken,
      );

      print('🔄 CREATE DOC: Converting to Firestore map...');
      var userDocumentMap = userDocument.toFirestore();
      
      print('📄 CREATE DOC: Document map contents:');
      userDocumentMap.forEach((key, value) {
        if (key == 'messagingToken') {
          print('   - $key: $value ${value == null ? "(NULL!)" : value.toString().isEmpty ? "(EMPTY!)" : "(OK)"}');
        } else {
          print('   - $key: $value');
        }
      });
      
      print('🔐 CREATE DOC: Adding user to trackers...');
      await _addUserIdentifierToTrackers(user);
      
      print('💾 CREATE DOC: Saving to Firestore...');
      await _firestore
          .collection("users")
          .doc(userDocument.uid)
          .set(userDocumentMap);
      
      print('✅ CREATE DOC: User document saved successfully!');
      print('=== CREATE USER DOCUMENT COMPLETE ===');
    } catch (e, stackTrace) {
      print('❌ CREATE DOC ERROR: $e');
      print('Stack trace: $stackTrace');
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  Future<void> _addUserIdentifierToTrackers(User user) async {
    // * add mixpanel user
    final mixPanelClient = await ref.read(mixpanelProvider.future);
    await mixPanelClient.identify(user.uid);

    // * add crashlytics user
    FirebaseCrashlytics.instance.setUserIdentifier(user.uid);

    // * add google analytics user
    final googleAnalyticsClient = await ref.read(firebaseAnalyticsProvider);
    googleAnalyticsClient.setUserId(id: user.uid);
  }

  Future<void> deleteUserDocument() async {
    try {
      return await _firestore
          .collection("users")
          .doc(_auth.currentUser?.uid)
          .delete();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  Future<bool> hasUserEverExisted(String? uid) async {
    try {
      if (uid == null) return false;

      // Check in a separate collection or use another method to track deleted accounts
      final docRef = await _firestore.collection('deletedUsers').doc(uid).get();
      return docRef.exists;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider),
      ref.watch(firestoreInstanceProvider), ref);
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
