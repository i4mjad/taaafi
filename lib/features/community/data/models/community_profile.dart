import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityProfile {
  final String id;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final bool postAnonymouslyByDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityProfile({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.postAnonymouslyByDefault,
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
      postAnonymouslyByDefault: data['postAnonymouslyByDefault'] ?? false,
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
      'postAnonymouslyByDefault': postAnonymouslyByDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
