import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NewUserDocument {
  final String uid;
  final List<String> devicesIds;
  final String displayName;
  final String email;
  final String gender;
  final String locale;
  final Timestamp dayOfBirth;
  final Timestamp userFirstDate;
  final String role;
  final String messagingToken;
  final List<String> bookmarkedContentIds;
  NewUserDocument({
    required this.uid,
    required this.devicesIds,
    required this.displayName,
    required this.email,
    required this.gender,
    required this.locale,
    required this.dayOfBirth,
    required this.userFirstDate,
    required this.role,
    required this.messagingToken,
    required this.bookmarkedContentIds,
  });

  NewUserDocument copyWith({
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
    List<String>? bookmarkedContentIds,
  }) {
    return NewUserDocument(
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
      bookmarkedContentIds: bookmarkedContentIds ?? this.bookmarkedContentIds,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'uid': uid});
    result.addAll({'devicesIds': devicesIds});
    result.addAll({'displayName': displayName});
    result.addAll({'email': email});
    result.addAll({'gender': gender});
    result.addAll({'locale': locale});
    result.addAll({'dayOfBirth': dayOfBirth});
    result.addAll({'userFirstDate': userFirstDate});
    result.addAll({'role': role});
    result.addAll({'messagingToken': messagingToken});
    result.addAll({'bookmarkedContentIds': bookmarkedContentIds});

    return result;
  }

  factory NewUserDocument.fromMap(Map<String, dynamic> map) {
    return NewUserDocument(
      uid: map['uid'] ?? '',
      devicesIds: map['devicesIds'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      locale: map['locale'] ?? '',
      dayOfBirth: map['dayOfBirth'],
      userFirstDate: map['userFirstDate'],
      role: map['role'] ?? '',
      messagingToken: map['messagingToken'] ?? '',
      bookmarkedContentIds: List<String>.from(map['bookmarkedContentIds']),
    );
  }

  String toJson() => json.encode(toMap());

  factory NewUserDocument.fromJson(String source) =>
      NewUserDocument.fromMap(json.decode(source));

  @override
  String toString() {
    return 'NewUserDocument(uid: $uid, devicesId: $devicesIds, displayName: $displayName, email: $email, gender: $gender, locale: $locale, dayOfBirth: $dayOfBirth, userFirstDate: $userFirstDate, role: $role, messagingToken: $messagingToken, bookmarkedContentIds: $bookmarkedContentIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NewUserDocument &&
        other.uid == uid &&
        other.devicesIds == devicesIds &&
        other.displayName == displayName &&
        other.email == email &&
        other.gender == gender &&
        other.locale == locale &&
        other.dayOfBirth == dayOfBirth &&
        other.userFirstDate == userFirstDate &&
        other.role == role &&
        other.messagingToken == messagingToken &&
        listEquals(other.bookmarkedContentIds, bookmarkedContentIds);
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
        bookmarkedContentIds.hashCode;
  }
}
