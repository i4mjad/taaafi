import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/services/promize_service.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;
  final IPromizeService _promizeService = getIt.get<IPromizeService>();
  FirebaseAuthMethods(this._auth);

  // FOR EVERY FUNCTION HERE
  // POP THE ROUTE USING: Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);

  // GET USER DATA
  // using null check operator since this method should be called only
  // when the user is logged in
  User get user => _auth.currentUser;

  // STATE PERSISTENCE STREAM
  Stream<User> get authState => FirebaseAuth.instance.authStateChanges();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

        await _auth.signInWithCredential(credential);

        _promizeService.createUser();

        // if you want to do specific task like storing information in firestore
        // only for new users using google sign in (since there are no two options
        // for google sign in and google sign up, only one as of now),
        // do the following:

        // if (userCredential.user != null) {
        //   if (userCredential.additionalUserInfo!.isNewUser) {}
        // }
      }
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message);
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();

      await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message);
    }
  }

  Future<void> reSignInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.currentUser.reauthenticateWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message);
    }
  }

  Future<void> reSignInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

        return await _auth.currentUser.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message);
    }
  }

  Future<void> signOut() async {
    await _promizeService.signOut();
    await _auth.signOut();
  }

  deleteAccount(BuildContext context) async {
    try {
      await FirebaseAuth.instance.currentUser.delete();
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.message);
    }
  }
}
