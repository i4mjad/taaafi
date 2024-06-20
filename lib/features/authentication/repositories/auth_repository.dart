import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/shared/services/auth/firebase_auth_methods.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

class AuthRepository {

  AuthRepository(this._auth,this._firebaseAuthMethods);
  final FirebaseAuth _auth;
  final FirebaseAuthMethods _firebaseAuthMethods;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<void> signOut() {
    return _firebaseAuthMethods.signOut();
  }

  Future<void> signInWithGoogle(BuildContext context) {
    return _firebaseAuthMethods.signInWithGoogle(context);
  }

  Future<void> signInWithApple(BuildContext context) {
    return _firebaseAuthMethods.signInWithApple(context);
  }

  Future<void> reSignInWithGoogle(BuildContext context) {
    return _firebaseAuthMethods.reSignInWithGoogle(context);
  }

  Future<void> reSignInWithApple(BuildContext context) {
    return _firebaseAuthMethods.reSignInWithApple(context);
  }



}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider),ref.watch(firebaseAuthMethodsProvider));
}

@riverpod
FirebaseAuthMethods firebaseAuthMethods(ref){
  return FirebaseAuthMethods(ref.watch(firebaseAuthProvider));
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}


