import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String gender;
  final String locale;
  final DateTime dayOfBirth;
  final DateTime userFirstDate;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.gender,
    required this.locale,
    required this.dayOfBirth,
    required this.userFirstDate,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      gender: data['gender'],
      locale: data['locale'],
      dayOfBirth: (data['dayOfBirth'] as Timestamp?)!.toDate(),
      userFirstDate: (data['userFirstDate'] as Timestamp?)!.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'locale': locale,
      'dayOfBirth': dayOfBirth != null ? Timestamp.fromDate(dayOfBirth) : null,
      'userFirstDate':
          userFirstDate != null ? Timestamp.fromDate(userFirstDate) : null,
    };
  }

  int? get age {
    if (dayOfBirth == null) {
      return null;
    }
    final today = DateTime.now();
    int age = today.year - dayOfBirth.year;
    if (today.month < dayOfBirth.month ||
        (today.month == dayOfBirth.month && today.day < dayOfBirth.day)) {
      age--;
    }
    return age;
  }
}
