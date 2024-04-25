import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  String? uid;
  String? displayName;
  String? email;
  String? gender;
  String? lcoale;

  DateTime? creationTime;

  DateTime? dayOfBirth;

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

  factory UserProfile.fromFireStore(User? user, Map<String, dynamic> data) {
    var userProfile = UserProfile(
      uid: user!.uid,
      displayName: user.displayName,
      email: user.email,
      creationTime: user.metadata.creationTime,
      gender: data["gender"] as String,
      lcoale: data["locale"] as String,
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
