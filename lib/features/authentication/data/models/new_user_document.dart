import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class NewUserDocument {
  final String uid;
  final String deviceId;
  final String displayName;
  final String email;
  final String gender;
  final String locale;
  final Timestamp dayOfBirth;
  final Timestamp userFirstDate;
  final String role;
  final String messagingToken;

  NewUserDocument({
    required this.uid,
    required this.deviceId,
    required this.displayName,
    required this.email,
    required this.gender,
    required this.locale,
    required this.dayOfBirth,
    required this.userFirstDate,
    required this.role,
    required this.messagingToken,
  });

  NewUserDocument copyWith({
    String? uid,
    String? deviceId,
    String? displayName,
    String? email,
    String? gender,
    String? locale,
    Timestamp? dayOfBirth,
    Timestamp? userFirstDate,
    String? role,
    String? messagingToken,
  }) {
    return NewUserDocument(
      uid: uid ?? this.uid,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      locale: locale ?? this.locale,
      dayOfBirth: dayOfBirth ?? this.dayOfBirth,
      userFirstDate: userFirstDate ?? this.userFirstDate,
      role: role ?? this.role,
      messagingToken: messagingToken ?? this.messagingToken,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'uid': uid});
    result.addAll({'deviceId': deviceId});
    result.addAll({'displayName': displayName});
    result.addAll({'email': email});
    result.addAll({'gender': gender});
    result.addAll({'locale': locale});
    result.addAll({'dayOfBirth': dayOfBirth});
    result.addAll({'userFirstDate': userFirstDate});
    result.addAll({'role': role});
    result.addAll({'messagingToken': messagingToken});

    return result;
  }

  factory NewUserDocument.fromMap(Map<String, dynamic> map) {
    return NewUserDocument(
      uid: map['uid'] ?? '',
      deviceId: map['deviceId'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      locale: map['locale'] ?? '',
      dayOfBirth: map['dayOfBirth'],
      userFirstDate: map['userFirstDate'],
      role: map['role'] ?? '',
      messagingToken: map['messagingToken'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory NewUserDocument.fromJson(String source) =>
      NewUserDocument.fromMap(json.decode(source));

  @override
  String toString() {
    return 'NewUserDocument(uid: $uid, deviceId: $deviceId, displayName: $displayName, email: $email, gender: $gender, locale: $locale, dayOfBirth: $dayOfBirth, userFirstDate: $userFirstDate, role: $role, messagingToken: $messagingToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NewUserDocument &&
        other.uid == uid &&
        other.deviceId == deviceId &&
        other.displayName == displayName &&
        other.email == email &&
        other.gender == gender &&
        other.locale == locale &&
        other.dayOfBirth == dayOfBirth &&
        other.userFirstDate == userFirstDate &&
        other.role == role &&
        other.messagingToken == messagingToken;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        deviceId.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        gender.hashCode ^
        locale.hashCode ^
        dayOfBirth.hashCode ^
        userFirstDate.hashCode ^
        role.hashCode ^
        messagingToken.hashCode;
  }
}
