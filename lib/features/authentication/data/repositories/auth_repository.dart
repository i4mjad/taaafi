import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/application/firebase_auth_methods.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

class AuthRepository {
  AuthRepository(this._auth, this._firebaseAuthMethods);
  final FirebaseAuth _auth;
  final FirebaseAuthMethods _firebaseAuthMethods;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _firebaseAuthMethods.signOut();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await _firebaseAuthMethods.signInWithGoogle(context);
  }

  Future<void> signInWithApple(BuildContext context) async {
    await _firebaseAuthMethods.signInWithApple(context);
  }

  Future<void> reSignInWithGoogle(BuildContext context) async {
    await _firebaseAuthMethods.reSignInWithGoogle(context);
  }

  Future<void> reSignInWithApple(BuildContext context) async {
    await _firebaseAuthMethods.reSignInWithApple(context);
  }

  Future<void> signInWithEmail(
      BuildContext context, String email, String password) async {
    await _firebaseAuthMethods.loginWithEmailAndPassword(
        context, email, password);
  }

  Future<void> signUpWithEmail(
      BuildContext context,
      String email,
      String password,
      String name,
      DateTime selectedDob,
      String gender,
      String locale,
      DateTime firstDate) async {
    return await _firebaseAuthMethods.createUserWithEmailAndPassword(
        context, email, password, name, selectedDob, gender, locale, firstDate);
  }

  Future<void> signUpWithProvider(
      BuildContext context,
      String name,
      DateTime selectedDob,
      String gender,
      String locale,
      DateTime firstDate) async {
    return await _firebaseAuthMethods.createUserDocument(
        context, name, selectedDob, gender, locale, firstDate);
  }


  Future<void> sendForgotPasswordLink(
      BuildContext context, String email) async {
    return await _firebaseAuthMethods.sendForgotPasswordLink(context, email);
  }

  Future<User?> getLoggedInUser() async {
    return await _auth.currentUser;
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
      ref.watch(firebaseAuthProvider), ref.watch(firebaseAuthMethodsProvider));
}

@riverpod
FirebaseAuthMethods firebaseAuthMethods(ref) {
  return FirebaseAuthMethods(
      ref.watch(firebaseAuthProvider), ref.watch(authServiceProvider));
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
