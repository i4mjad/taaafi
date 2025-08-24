import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int capacity;
  final String gender;
  final String joinMethod; // 'any' | 'admin_only' | 'code_only'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.capacity,
    required this.gender,
    required this.joinMethod,
    required this.createdAt,
    this.updatedAt,
  });

  factory Group.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Group(
        id: doc.id,
        name: doc.data()!["name"],
        description: doc.data()!["description"],
        memberCount: doc.data()!["memberCount"] ?? 0,
        capacity: doc.data()!["capacity"],
        gender: doc.data()!["gender"],
        joinMethod: doc.data()!["joinMethod"] ?? 'any',
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'memberCount': memberCount,
        'capacity': capacity,
        'gender': gender,
        'joinMethod': joinMethod,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
