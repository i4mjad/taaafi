import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

class AuthRepository {
  AuthRepository(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> getLoggedInUser() async {
    return await _auth.currentUser;
  }

  Future<bool> isUserDocumentExist() async {
    print("Checking if user document exists for: ${_auth.currentUser?.uid}");
    final docRef =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    print("Document exists: ${docRef.exists}");
    return docRef.exists; // Correctly check if the document exists
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
    if (user == null) {
      return null;
    }
    final userDocument = NewUserDocument(
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
          userDocument.toMap(),
        );

    final documentExist = await isUserDocumentExist();
    if (documentExist == true) {
      context.goNamed(RouteNames.home.name);
    }
  }

  Future<void> deleteUserDocument() async {
    return await _firestore
        .collection("users")
        .doc(_auth.currentUser?.uid)
        .delete();
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
      ref.watch(firebaseAuthProvider), ref.watch(firestoreInstanceProvider));
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
