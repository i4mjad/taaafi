import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String name;
  final String description;
  final DateTime start;
  final DateTime end;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.start,
    required this.end,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Challenge.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Challenge(
        id: doc.id,
        name: doc.data()!["name"],
        description: doc.data()!["description"],
        start: (doc.data()!["start"] as Timestamp).toDate(),
        end: (doc.data()!["end"] as Timestamp).toDate(),
        isActive: doc.data()!["isActive"] ?? false,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
