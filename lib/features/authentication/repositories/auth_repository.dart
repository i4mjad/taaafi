import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/providers/user/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() {
    return _auth.signInAnonymously();
  }
}

@riverpod
AuthRepository authRepository(ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
}

@riverpod
Stream<User?> authStateChanges(ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
