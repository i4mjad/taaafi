import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class GoogleAuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  GoogleAuthenticationService(this._firebaseAuth);

  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount googleUser =
        await GoogleSignIn(scopes: ["email"]).signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> reauthenticateWithsignInWithGoogle() async {
    final GoogleSignInAccount googleUser =
        await GoogleSignIn(scopes: ["email"]).signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.currentUser
        .reauthenticateWithCredential(credential);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print(
            'The user must reauthenticate before this operation can be executed.');
      }
      print(e.code);
    }
  }
}

class NewUsersService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;

  final FirebaseFirestore _firebaseFirestore;

  bool isExist;
  NewUsersService(this._firebaseFirestore, this._firebaseAuth);

  bool get isUserDocumentExist => isExist;

  //     .asStream();

  isDocExist() {
    bool _isDocExist = false;
    _firebaseFirestore
        .collection("users")
        .doc(_firebaseAuth.currentUser.uid)
        .get()
        .then((value) {
      _isDocExist = value.exists;
    });
    notifyListeners();
  }
}
