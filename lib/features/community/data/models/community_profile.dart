import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityProfile {
  final String id;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final bool postAnonymouslyByDefault;
  final String? referralCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityProfile({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.postAnonymouslyByDefault,
    this.referralCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityProfile.fromFirestore(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      CommunityProfile(
        id: doc.id,
        displayName: doc.data()!["displayName"],
        gender: doc.data()!["gender"],
        avatarUrl: doc.data()!["avatarUrl"],
        postAnonymouslyByDefault:
            doc.data()!["postAnonymouslyByDefault"] ?? false,
        referralCode: doc.data()!["referralCode"],
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'gender': gender,
        'avatarUrl': avatarUrl,
        'postAnonymouslyByDefault': postAnonymouslyByDefault,
        'referralCode': referralCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
