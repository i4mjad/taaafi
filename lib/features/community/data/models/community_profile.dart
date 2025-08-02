import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityProfile {
  final String id;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final bool isAnonymous;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityProfile({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.isAnonymous,
    this.isDeleted = false,
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
      isDeleted: data['isDeleted'] ?? false, // This already exists
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
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Business logic: Get display name following the pipeline: deleted → anonymous → actual name
  String getDisplayNameWithPipeline() {
    print('🔍 [CommunityProfile] Pipeline check for profile $id:');
    print('🔍 [CommunityProfile] - Display Name: "$displayName"');
    print('🔍 [CommunityProfile] - Is Deleted: $isDeleted');
    print('🔍 [CommunityProfile] - Is Anonymous: $isAnonymous');

    // 1. First check if user is deleted - if yes, display "deleted" text
    if (isDeleted) {
      print('🔍 [CommunityProfile] -> Returning DELETED_USER');
      return 'DELETED_USER'; // This will be localized in the UI
    }

    // 2. Then check if they are anonymous - if yes, don't show their name
    if (isAnonymous) {
      print('🔍 [CommunityProfile] -> Returning ANONYMOUS_USER');
      return 'ANONYMOUS_USER'; // This will be localized in the UI
    }

    // 3. If neither deleted nor anonymous, display their actual name
    final result = displayName.isNotEmpty ? displayName : 'Community Member';
    print('🔍 [CommunityProfile] -> Returning actual name: "$result"');
    return result;
  }
}
