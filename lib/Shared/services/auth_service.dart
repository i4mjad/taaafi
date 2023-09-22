import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reboot_app_3/di/container.dart';
import 'dart:async';

import 'package:reboot_app_3/shared/services/promize_service.dart';

class GoogleAuthenticationService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final IPromizeService _promizeService = getIt.get<IPromizeService>();

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

    var userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    await _promizeService.createUser();

    return userCredential;
  }

  Future<UserCredential> reauthenticateWithCredential() async {
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
    await _promizeService.signOut();
    await _firebaseAuth.signOut();
  }

  deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        //ُTODO: consider displaying the error in a snack bar
        print(
            'The user must reauthenticate before this operation can be executed.');
      }
      print(e);
    }
  }
}
