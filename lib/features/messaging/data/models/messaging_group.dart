import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingGroup {
  final String id;
  final DateTime createdAt;
  final String description;
  final String descriptionAr;
  final bool isActive;
  final bool isForPlusUsers;
  final int memberCount;
  final String name;
  final String nameAr;
  final String topicId;
  final DateTime updatedAt;

  const MessagingGroup({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.descriptionAr,
    required this.isActive,
    required this.isForPlusUsers,
    required this.memberCount,
    required this.name,
    required this.nameAr,
    required this.topicId,
    required this.updatedAt,
  });

  factory MessagingGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessagingGroup(
      id: doc.id,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      description: data['description'] ?? '',
      descriptionAr: data['descriptionAr'] ?? '',
      isActive: data['isActive'] ?? false,
      isForPlusUsers: data['isForPlusUsers'] ?? false,
      memberCount: data['memberCount'] ?? 0,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      topicId: data['topicId'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'descriptionAr': descriptionAr,
      'isActive': isActive,
      'isForPlusUsers': isForPlusUsers,
      'memberCount': memberCount,
      'name': name,
      'nameAr': nameAr,
      'topicId': topicId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MessagingGroup copyWith({
    String? id,
    DateTime? createdAt,
    String? description,
    String? descriptionAr,
    bool? isActive,
    bool? isForPlusUsers,
    int? memberCount,
    String? name,
    String? nameAr,
    String? topicId,
    DateTime? updatedAt,
  }) {
    return MessagingGroup(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      isActive: isActive ?? this.isActive,
      isForPlusUsers: isForPlusUsers ?? this.isForPlusUsers,
      memberCount: memberCount ?? this.memberCount,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      topicId: topicId ?? this.topicId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
