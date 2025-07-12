import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorCPId;
  final String body;
  final String parentFor;
  final String parentId;
  final bool isAnonymous;
  final int score;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.authorCPId,
    required this.body,
    required this.parentFor,
    required this.parentId,
    required this.isAnonymous,
    required this.score,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Comment(
        id: doc.id,
        authorCPId: doc.data()!["authorCPId"],
        body: doc.data()!["body"],
        parentFor: doc.data()!["parentFor"],
        parentId: doc.data()!["parentId"],
        isAnonymous: doc.data()!["isAnonymous"],
        score: doc.data()!["score"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorCPId': authorCPId,
        'body': body,
        'parentFor': parentFor,
        'parentId': parentId,
        'isAnonymous': isAnonymous,
        'score': score,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
