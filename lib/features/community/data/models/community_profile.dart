import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityProfile {
  final String id;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityProfile({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.isAnonymous,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityProfile(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      gender: data['gender'] ?? '',
      avatarUrl: data['avatarUrl'],
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
