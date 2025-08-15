import 'package:cloud_firestore/cloud_firestore.dart';

class UserGroupMembership {
  final String groupName;
  final String groupNameAr;
  final DateTime subscribedAt;
  final String topicId;
  final DateTime updatedAt;
  final String userId;

  const UserGroupMembership({
    required this.groupName,
    required this.groupNameAr,
    required this.subscribedAt,
    required this.topicId,
    required this.updatedAt,
    required this.userId,
  });

  factory UserGroupMembership.fromMap(Map<String, dynamic> data) {
    return UserGroupMembership(
      groupName: data['groupName'] ?? '',
      groupNameAr: data['groupNameAr'] ?? '',
      subscribedAt: data['subscribedAt'] != null
          ? (data['subscribedAt'] as Timestamp).toDate()
          : DateTime.now(),
      topicId: data['topicId'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'groupNameAr': groupNameAr,
      'subscribedAt': Timestamp.fromDate(subscribedAt),
      'topicId': topicId,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  UserGroupMembership copyWith({
    String? groupName,
    String? groupNameAr,
    DateTime? subscribedAt,
    String? topicId,
    DateTime? updatedAt,
    String? userId,
  }) {
    return UserGroupMembership(
      groupName: groupName ?? this.groupName,
      groupNameAr: groupNameAr ?? this.groupNameAr,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      topicId: topicId ?? this.topicId,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}

class UserGroupMemberships {
  final String userId;
  final List<UserGroupMembership> groups;

  const UserGroupMemberships({
    required this.userId,
    required this.groups,
  });

  factory UserGroupMemberships.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final groupsList = data['groups'] as List<dynamic>? ?? [];

    return UserGroupMemberships(
      userId: data['userId'] as String? ??
          doc.id, // Use field value or fallback to doc.id
      groups: groupsList
          .map((groupData) =>
              UserGroupMembership.fromMap(groupData as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groups': groups.map((membership) => membership.toMap()).toList(),
      'updatedAt': Timestamp.now(),
      'groupCount': groups.length,
    };
  }

  UserGroupMemberships copyWith({
    String? userId,
    List<UserGroupMembership>? groups,
  }) {
    return UserGroupMemberships(
      userId: userId ?? this.userId,
      groups: groups ?? this.groups,
    );
  }
}
