import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dart:async';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);

  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    // Initiate the auth procedure
    final GoogleSignInAccount googleUser =
        await GoogleSignIn(scopes: ["email"]).signIn();
    // fetch the auth details from the request made earlier
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    // Create a new credential for signing in with google
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
