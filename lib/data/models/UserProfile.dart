import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String gender;
  final String lcoale;

  final DateTime creationTime;

  final DateTime dayOfBirth;

  UserProfile({
    this.uid,
    this.displayName,
    this.email,
    this.creationTime,
    this.lcoale,
    this.gender,
    this.dayOfBirth,
  });

  static UserProfile Missing = new UserProfile();

  factory UserProfile.fromFireStore(User user, Map<String, Object> data) {
    var userProfile = UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      creationTime: user.metadata.creationTime,
      gender: data["gender"],
      lcoale: data["locale"],
      dayOfBirth: DateTime.fromMillisecondsSinceEpoch(
          (data["dayOfBirth"] as Timestamp).millisecondsSinceEpoch),
    );

    return userProfile;
  }

  factory UserProfile.toMap(User user) {
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? "",
      email: user.email ?? "",
      creationTime: user.metadata.creationTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'user': uid,
        'email': email,
        'name': displayName,
        'creationTime': creationTime,
        'locale': lcoale,
        'gender': gender,
        'dayOfBirth': dayOfBirth,
      };
}
