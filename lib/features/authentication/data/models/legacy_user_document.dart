import 'package:cloud_firestore/cloud_firestore.dart';

class LegacyUserDocument {
  final String id;
  final String? displayName;
  final String? email;
  final String? gender;
  final String? locale;
  final String? uid;
  final Timestamp? dayOfBirth;
  final Timestamp? userFirstDate;
  final List<String>? userRelapses;
  final List<String>? userMasturbatingWithoutWatching;
  final List<String>? userWatchingWithoutMasturbating;
  final String? role;

  LegacyUserDocument({
    required this.id,
    this.displayName,
    this.email,
    this.gender,
    this.locale,
    this.uid,
    this.dayOfBirth,
    this.userFirstDate,
    this.userRelapses,
    this.userMasturbatingWithoutWatching,
    this.userWatchingWithoutMasturbating,
    this.role,
  });

  // Create a LegacyUserDocument from a Firestore document
  factory LegacyUserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegacyUserDocument(
      id: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      gender: data['gender'],
      locale: data['locale'],
      uid: data['uid'],
      dayOfBirth: data['dayOfBirth'],
      userFirstDate: data['userFirstDate'],
      userRelapses: data['userRelapses'] != null ? List<String>.from(data['userRelapses']) : null,
      userMasturbatingWithoutWatching: data['userMasturbatingWithoutWatching'] != null ? List<String>.from(data['userMasturbatingWithoutWatching']) : null,
      userWatchingWithoutMasturbating: data['userWatchingWithoutMasturbating'] != null ? List<String>.from(data['userWatchingWithoutMasturbating']) : null,
      role: data['role'],
    );
  }

  // Convert LegacyUserDocument to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'locale': locale,
      'uid': uid,
      'dayOfBirth': dayOfBirth,
      'userFirstDate': userFirstDate,
      'userRelapses': userRelapses,
      'userMasturbatingWithoutWatching': userMasturbatingWithoutWatching,
      'userWatchingWithoutMasturbating': userWatchingWithoutMasturbating,
      'role': role,
    };
  }

  // Define the copyWith method
  LegacyUserDocument copyWith({
    String? id,
    String? displayName,
    String? email,
    String? gender,
    String? locale,
    String? uid,
    Timestamp? dayOfBirth,
    Timestamp? userFirstDate,
    List<String>? userRelapses,
    List<String>? userMasturbatingWithoutWatching,
    List<String>? userWatchingWithoutMasturbating,
    String? role,
  }) {
    return LegacyUserDocument(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      locale: locale ?? this.locale,
      uid: uid ?? this.uid,
      dayOfBirth: dayOfBirth ?? this.dayOfBirth,
      userFirstDate: userFirstDate ?? this.userFirstDate,
      userRelapses: userRelapses ?? this.userRelapses,
      userMasturbatingWithoutWatching: userMasturbatingWithoutWatching ?? this.userMasturbatingWithoutWatching,
      userWatchingWithoutMasturbating: userWatchingWithoutMasturbating ?? this.userWatchingWithoutMasturbating,
      role: role ?? this.role,
    );
  }
}
