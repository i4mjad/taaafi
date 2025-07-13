import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorCPId;
  final String title;
  final String body;
  final String category;
  final int score;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.authorCPId,
    required this.title,
    required this.body,
    required this.category,
    required this.score,
    required this.createdAt,
    this.updatedAt,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Post(
        id: doc.id,
        authorCPId: doc.data()!["authorCPId"],
        title: doc.data()!["title"],
        body: doc.data()!["body"],
        category: doc.data()!["category"],
        score: doc.data()!["score"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorCPId': authorCPId,
        'title': title,
        'body': body,
        'category': category,
        'score': score,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Converts Post to Firestore document data
  /// Excludes the id field as it's stored as the document ID
  Map<String, dynamic> toFirestore() => {
        'authorCPId': authorCPId,
        'title': title,
        'body': body,
        'category': category,
        'score': score,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
