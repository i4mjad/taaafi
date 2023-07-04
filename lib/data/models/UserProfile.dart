import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String locale;
  final DateTime creationTime;
  final DateTime lastSignInTime;

  UserProfile({
    this.locale,
    this.uid,
    this.displayName,
    this.email,
    this.creationTime,
    this.lastSignInTime,
  });

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? "",
      email: user.email ?? "",
      creationTime: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
      locale: "", //TODO: add this later
    );
  }
}
