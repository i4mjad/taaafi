import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  @override
  FutureOr<User?> build() async {
    // Listen to auth state changes to detect email verification updates
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (state.value != user) {
        state = AsyncValue.data(user);
      }
    });

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return _auth.currentUser;
  }
}
