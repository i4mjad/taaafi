import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserDocument {
  final String? uid;
  final List<String>? devicesIds;
  final String? displayName;
  final String? email;
  final String? gender;
  final String? locale;
  final Timestamp? dayOfBirth;
  final Timestamp? userFirstDate;
  final String? role;
  final String? messagingToken;

  final List<String>? userRelapses;
  final List<String>? userMasturbatingWithoutWatching;
  final List<String>? userWatchingWithoutMasturbating;

  UserDocument({
    this.uid,
    this.devicesIds,
    this.displayName,
    this.email,
    this.gender,
    this.locale,
    this.dayOfBirth,
    this.userFirstDate,
    this.role,
    this.messagingToken,
    this.userRelapses,
    this.userMasturbatingWithoutWatching,
    this.userWatchingWithoutMasturbating,
  });

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDocument(
      uid: data['uid'],
      devicesIds: data['devicesIds'] != null
          ? List<String>.from(data['devicesIds'])
          : null,
      displayName: data['displayName'],
      email: data['email'],
      gender: data['gender'],
      locale: data['locale'],
      dayOfBirth: data['dayOfBirth'],
      userFirstDate: data['userFirstDate'],
      role: data['role'],
      messagingToken: data['messagingToken'],
      userRelapses: data['userRelapses'] != null
          ? List<String>.from(data['userRelapses'])
          : null,
      userMasturbatingWithoutWatching:
          !data.containsKey('userMasturbatingWithoutWatching')
              ? null
              : List<String>.from(data['userMasturbatingWithoutWatching']),
      userWatchingWithoutMasturbating:
          data['userWatchingWithoutMasturbating'] != null
              ? List<String>.from(data['userWatchingWithoutMasturbating'])
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'devicesIds': devicesIds,
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'locale': locale,
      'dayOfBirth': dayOfBirth,
      'userFirstDate': userFirstDate,
      'role': role,
      'messagingToken': messagingToken,
      'userRelapses': userRelapses ?? [],
      'userMasturbatingWithoutWatching': userMasturbatingWithoutWatching ?? [],
      'userWatchingWithoutMasturbating': userWatchingWithoutMasturbating ?? [],
    };
  }

  String toJson() => json.encode(toFirestore());

  factory UserDocument.fromJson(String source) =>
      UserDocument.fromFirestore(json.decode(source));

  @override
  String toString() {
    return 'UserDocument( uid: $uid, devicesIds: $devicesIds, displayName: $displayName, email: $email, gender: $gender, locale: $locale, dayOfBirth: $dayOfBirth, userFirstDate: $userFirstDate, role: $role, messagingToken: $messagingToken, userRelapses: $userRelapses, userMasturbatingWithoutWatching: $userMasturbatingWithoutWatching, userWatchingWithoutMasturbating: $userWatchingWithoutMasturbating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserDocument &&
        other.uid == uid &&
        listEquals(other.devicesIds, devicesIds) &&
        other.displayName == displayName &&
        other.email == email &&
        other.gender == gender &&
        other.locale == locale &&
        other.dayOfBirth == dayOfBirth &&
        other.userFirstDate == userFirstDate &&
        other.role == role &&
        other.messagingToken == messagingToken &&
        listEquals(other.userRelapses, userRelapses) &&
        listEquals(other.userMasturbatingWithoutWatching,
            userMasturbatingWithoutWatching) &&
        listEquals(other.userWatchingWithoutMasturbating,
            userWatchingWithoutMasturbating);
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        devicesIds.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        gender.hashCode ^
        locale.hashCode ^
        dayOfBirth.hashCode ^
        userFirstDate.hashCode ^
        role.hashCode ^
        messagingToken.hashCode ^
        userRelapses.hashCode ^
        userMasturbatingWithoutWatching.hashCode ^
        userWatchingWithoutMasturbating.hashCode;
  }
}
