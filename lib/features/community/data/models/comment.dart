import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorCPId;
  final String body;
  final bool isDeleted;
  final bool isHidden;
  final int score;
  final int likeCount;
  final int dislikeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Nested comment fields
  final String parentFor; // 'post' or 'comment'
  final String parentId; // post ID or parent comment ID
  final int replyCount; // Number of direct replies

  const Comment({
    required this.id,
    required this.postId,
    required this.authorCPId,
    required this.body,
    this.isDeleted = false,
    this.isHidden = false,
    required this.score,
    required this.likeCount,
    required this.dislikeCount,
    required this.createdAt,
    this.updatedAt,
    required this.parentFor,
    required this.parentId,
    this.replyCount = 0,
  });

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Comment(
        id: doc.id,
        postId: doc.data()!["postId"],
        authorCPId: doc.data()!["authorCPId"],
        body: doc.data()!["body"],
        isDeleted: doc.data()!["isDeleted"] ?? false,
        isHidden: doc.data()!["isHidden"] ?? false,
        score: doc.data()!["score"] ?? 0,
        likeCount: doc.data()!["likeCount"] ?? 0,
        dislikeCount: doc.data()!["dislikeCount"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp?)?.toDate() ??
            DateTime.now(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
        parentFor: doc.data()!["parentFor"] ?? "post",
        parentId: doc.data()!["parentId"] ?? doc.data()!["postId"],
        replyCount: doc.data()!["replyCount"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorCPId': authorCPId,
        'body': body,
        'isDeleted': isDeleted,
        'isHidden': isHidden,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'parentFor': parentFor,
        'parentId': parentId,
        'replyCount': replyCount,
      };

  /// Converts Comment to Firestore document data
  /// Excludes the id field as it's stored as the document ID
  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'authorCPId': authorCPId,
        'body': body,
        'isDeleted': isDeleted,
        'isHidden': isHidden,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'parentFor': parentFor,
        'parentId': parentId,
        'replyCount': replyCount,
      };

  /// Creates a copy of this comment with updated values
  Comment copyWith({
    String? id,
    String? postId,
    String? authorCPId,
    String? body,
    bool? isDeleted,
    bool? isHidden,
    int? score,
    int? likeCount,
    int? dislikeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentFor,
    String? parentId,
    int? replyCount,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorCPId: authorCPId ?? this.authorCPId,
      body: body ?? this.body,
      isDeleted: isDeleted ?? this.isDeleted,
      isHidden: isHidden ?? this.isHidden,
      score: score ?? this.score,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentFor: parentFor ?? this.parentFor,
      parentId: parentId ?? this.parentId,
      replyCount: replyCount ?? this.replyCount,
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
        other.isDeleted == isDeleted &&
        other.isHidden == isHidden &&
        other.score == score &&
        other.likeCount == likeCount &&
        other.dislikeCount == dislikeCount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.parentFor == parentFor &&
        other.parentId == parentId &&
        other.replyCount == replyCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      authorCPId,
      body,
      isDeleted,
      isHidden,
      score,
      likeCount,
      dislikeCount,
      createdAt,
      updatedAt,
      parentFor,
      parentId,
      replyCount,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, authorCPId: $authorCPId, body: $body, isDeleted: $isDeleted, isHidden: $isHidden, score: $score, likeCount: $likeCount, dislikeCount: $dislikeCount, createdAt: $createdAt, updatedAt: $updatedAt, parentFor: $parentFor, parentId: $parentId, replyCount: $replyCount)';
  }

  // Helper methods for nested comments
  bool get isTopLevelComment => parentFor == 'post';
  bool get isReply => parentFor == 'comment';
  bool get hasReplies => replyCount > 0;
}
