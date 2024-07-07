import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  FutureOr<User?> build() async {
    return _fetchLoggedInUser();
  }

  Future<User?> _fetchLoggedInUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }
}
