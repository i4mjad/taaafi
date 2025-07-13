import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorCPId;
  final String body;
  final int score;
  final int likeCount;
  final int dislikeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorCPId,
    required this.body,
    required this.score,
    required this.likeCount,
    required this.dislikeCount,
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
        likeCount: doc.data()!["likeCount"] ?? 0,
        dislikeCount: doc.data()!["dislikeCount"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorCPId': authorCPId,
        'body': body,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Converts Comment to Firestore document data
  /// Excludes the id field as it's stored as the document ID
  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'authorCPId': authorCPId,
        'body': body,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Creates a copy of this comment with updated values
  Comment copyWith({
    String? id,
    String? postId,
    String? authorCPId,
    String? body,
    int? score,
    int? likeCount,
    int? dislikeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorCPId: authorCPId ?? this.authorCPId,
      body: body ?? this.body,
      score: score ?? this.score,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.postId == postId &&
        other.authorCPId == authorCPId &&
        other.body == body &&
        other.score == score &&
        other.likeCount == likeCount &&
        other.dislikeCount == dislikeCount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      authorCPId,
      body,
      score,
      likeCount,
      dislikeCount,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, authorCPId: $authorCPId, body: $body, score: $score, likeCount: $likeCount, dislikeCount: $dislikeCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
