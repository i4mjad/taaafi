import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
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
      return docRef.exists; // Correctly check if the document exists
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
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
      if (user == null) {
        return;
      }
      final userDocument = UserDocument(
        uid: user.uid,
        devicesIds: [deviceId],
        displayName: name,
        email: user.email!,
        gender: gender,
        locale: locale,
        dayOfBirth: Timestamp.fromDate(dob.toUtc()),
        userFirstDate: Timestamp.fromDate(firstDate.toUtc()),
        role: "user",
        messagingToken: messagingToken,
        bookmarkedContentIds: [],
      );

      await _firestore.collection("users").doc(userDocument.uid).set(
            userDocument.toFirestore(),
          );

      final documentExist = await isUserDocumentExist();
      if (documentExist == true) {
        context.goNamed(RouteNames.home.name);
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
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
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider),
      ref.watch(firestoreInstanceProvider), ref);
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
