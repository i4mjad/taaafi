import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorCPId;
  final String title;
  final String body;
  final String category;
  final bool isPinned;
  final bool isDeleted;
  final bool isCommentingAllowed;
  final int score;
  final int likeCount;
  final int dislikeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.authorCPId,
    required this.title,
    required this.body,
    required this.category,
    this.isPinned = false,
    this.isDeleted = false,
    this.isCommentingAllowed = true,
    required this.score,
    required this.likeCount,
    required this.dislikeCount,
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
        isPinned: doc.data()!["isPinned"] ?? false,
        isDeleted: doc.data()!["isDeleted"] ?? false,
        isCommentingAllowed: doc.data()!["isCommentingAllowed"] ?? true,
        score: doc.data()!["score"] ?? 0,
        likeCount: doc.data()!["likeCount"] ?? 0,
        dislikeCount: doc.data()!["dislikeCount"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorCPId': authorCPId,
        'title': title,
        'body': body,
        'category': category,
        'isPinned': isPinned,
        'isDeleted': isDeleted,
        'isCommentingAllowed': isCommentingAllowed,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
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
        'isPinned': isPinned,
        'isDeleted': isDeleted,
        'isCommentingAllowed': isCommentingAllowed,
        'score': score,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Creates a copy of this post with updated values
  Post copyWith({
    String? id,
    String? authorCPId,
    String? title,
    String? body,
    String? category,
    bool? isPinned,
    bool? isDeleted,
    bool? isCommentingAllowed,
    int? score,
    int? likeCount,
    int? dislikeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      authorCPId: authorCPId ?? this.authorCPId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      isCommentingAllowed: isCommentingAllowed ?? this.isCommentingAllowed,
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
    return other is Post &&
        other.id == id &&
        other.authorCPId == authorCPId &&
        other.title == title &&
        other.body == body &&
        other.category == category &&
        other.isPinned == isPinned &&
        other.isDeleted == isDeleted &&
        other.isCommentingAllowed == isCommentingAllowed &&
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
      authorCPId,
      title,
      body,
      category,
      isPinned,
      isDeleted,
      isCommentingAllowed,
      score,
      likeCount,
      dislikeCount,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, authorCPId: $authorCPId, title: $title, body: $body, category: $category, isPinned: $isPinned, isDeleted: $isDeleted, isCommentingAllowed: $isCommentingAllowed, score: $score, likeCount: $likeCount, dislikeCount: $dislikeCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
