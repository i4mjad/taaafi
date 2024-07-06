import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;
  final AuthService _authService;

  FirebaseAuthMethods(this._auth, this._authService);

  // FOR EVERY FUNCTION HERE
  // POP THE ROUTE USING: Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);

  // GET USER DATA
  // using null check operator since this method should be called only
  // when the user is logged in
  User? get user => _auth.currentUser;

  // STATE PERSISTENCE STREAM
  Stream<User?> get authState => FirebaseAuth.instance.authStateChanges();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();

      await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> reSignInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.currentUser?.reauthenticateWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> reSignInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

        await _auth.currentUser?.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> createUserWithEmailAndPassword(
    BuildContext context,
    String emailAddress,
    String password,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
  ) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      var user = credential.user;
      _authService.createUserDocument(
          user!, name, dob, gender, locale, firstDate);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message ?? e.toString());
    } catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> loginWithEmailAndPassword(
    BuildContext context,
    String emailAddress,
    String password,
  ) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);
    } on FirebaseAuthException catch (e) {
      getSnackBar(context, e.code);
    } catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }
}
