import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorCPId;
  final String body;
  final int score;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorCPId,
    required this.body,
    required this.score,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Comment(
        id: doc.id,
        postId: doc.data()!["postId"],
        authorCPId: doc.data()!["authorCPId"],
        body: doc.data()!["body"],
        score: doc.data()!["score"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorCPId': authorCPId,
        'body': body,
        'score': score,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
