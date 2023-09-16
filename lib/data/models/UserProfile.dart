import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime creationTime;
  final DateTime lastSignInTime;

  UserProfile({
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
    );
  }
  factory UserProfile.toMap(User user) {
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? "",
      email: user.email ?? "",
      creationTime: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
    );
  }

  Map<String, dynamic> toJson(String locale, String gender, DateTime dob) => {
        'user': uid,
        'email': email,
        'name': displayName,
        'creationTime': creationTime,
        'lastSignInTime': lastSignInTime,
        'locale': locale,
        'gender': gender,
        'dayOfBirth': dob,
      };
}
