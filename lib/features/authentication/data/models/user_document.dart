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

  // Plus subscription tracking fields
  final bool? isPlusUser;
  final Timestamp? lastPlusCheck;

  // Account deletion tracking field
  final bool? isRequestedToBeDeleted;

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
    this.isPlusUser,
    this.lastPlusCheck,
    this.isRequestedToBeDeleted,
  });

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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
      isPlusUser: data['isPlusUser'],
      lastPlusCheck: data['lastPlusCheck'],
      isRequestedToBeDeleted: data['isRequestedToBeDeleted'],
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
      'isPlusUser': isPlusUser,
      'lastPlusCheck': lastPlusCheck,
      'isRequestedToBeDeleted': isRequestedToBeDeleted,
    };
  }

  String toJson() => json.encode(toFirestore());

  factory UserDocument.fromJson(String source) =>
      UserDocument.fromFirestore(json.decode(source));

  @override
  String toString() {
    return 'UserDocument( uid: $uid, devicesIds: $devicesIds, displayName: $displayName, email: $email, gender: $gender, locale: $locale, dayOfBirth: $dayOfBirth, userFirstDate: $userFirstDate, role: $role, messagingToken: $messagingToken, userRelapses: $userRelapses, userMasturbatingWithoutWatching: $userMasturbatingWithoutWatching, userWatchingWithoutMasturbating: $userWatchingWithoutMasturbating, isPlusUser: $isPlusUser, lastPlusCheck: $lastPlusCheck, isRequestedToBeDeleted: $isRequestedToBeDeleted)';
  }

  UserDocument copyWith({
    String? uid,
    List<String>? devicesIds,
    String? displayName,
    String? email,
    String? gender,
    String? locale,
    Timestamp? dayOfBirth,
    Timestamp? userFirstDate,
    String? role,
    String? messagingToken,
    List<String>? userRelapses,
    List<String>? userMasturbatingWithoutWatching,
    List<String>? userWatchingWithoutMasturbating,
    bool? isPlusUser,
    Timestamp? lastPlusCheck,
    bool? isRequestedToBeDeleted,
  }) {
    return UserDocument(
      uid: uid ?? this.uid,
      devicesIds: devicesIds ?? this.devicesIds,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      locale: locale ?? this.locale,
      dayOfBirth: dayOfBirth ?? this.dayOfBirth,
      userFirstDate: userFirstDate ?? this.userFirstDate,
      role: role ?? this.role,
      messagingToken: messagingToken ?? this.messagingToken,
      userRelapses: userRelapses ?? this.userRelapses,
      userMasturbatingWithoutWatching: userMasturbatingWithoutWatching ??
          this.userMasturbatingWithoutWatching,
      userWatchingWithoutMasturbating: userWatchingWithoutMasturbating ??
          this.userWatchingWithoutMasturbating,
      isPlusUser: isPlusUser ?? this.isPlusUser,
      lastPlusCheck: lastPlusCheck ?? this.lastPlusCheck,
      isRequestedToBeDeleted: isRequestedToBeDeleted ?? this.isRequestedToBeDeleted,
    );
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
            userWatchingWithoutMasturbating) &&
        other.isPlusUser == isPlusUser &&
        other.lastPlusCheck == lastPlusCheck &&
        other.isRequestedToBeDeleted == isRequestedToBeDeleted;
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
        userWatchingWithoutMasturbating.hashCode ^
        isPlusUser.hashCode ^
        lastPlusCheck.hashCode ^
        isRequestedToBeDeleted.hashCode;
  }
}
