import 'package:reboot_app_3/features/community/data/models/comment.dart';

/// Represents a comment thread with a parent comment and its replies
class CommentThread {
  final Comment parentComment;
  final List<Comment> replies;
  final bool hasMoreReplies;
  final int totalReplyCount;
  final int loadedReplyCount;

  const CommentThread({
    required this.parentComment,
    required this.replies,
    this.hasMoreReplies = false,
    required this.totalReplyCount,
    required this.loadedReplyCount,
  });

  /// Factory constructor for creating an empty thread
  factory CommentThread.empty(Comment parentComment) {
    return CommentThread(
      parentComment: parentComment,
      replies: [],
      hasMoreReplies: false,
      totalReplyCount: 0,
      loadedReplyCount: 0,
    );
  }

  /// Creates a copy with updated values
  CommentThread copyWith({
    Comment? parentComment,
    List<Comment>? replies,
    bool? hasMoreReplies,
    int? totalReplyCount,
    int? loadedReplyCount,
  }) {
    return CommentThread(
      parentComment: parentComment ?? this.parentComment,
      replies: replies ?? this.replies,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      totalReplyCount: totalReplyCount ?? this.totalReplyCount,
      loadedReplyCount: loadedReplyCount ?? this.loadedReplyCount,
    );
  }

  /// Adds a new reply to the thread
  CommentThread addReply(Comment reply) {
    final updatedReplies = List<Comment>.from(replies)..add(reply);
    return copyWith(
      replies: updatedReplies,
      totalReplyCount: totalReplyCount + 1,
      loadedReplyCount: loadedReplyCount + 1,
    );
  }

  /// Removes a reply from the thread
  CommentThread removeReply(String replyId) {
    final updatedReplies = replies.where((r) => r.id != replyId).toList();
    return copyWith(
      replies: updatedReplies,
      totalReplyCount: totalReplyCount - 1,
      loadedReplyCount: loadedReplyCount - 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentThread &&
        other.parentComment == parentComment &&
        other.replies.length == replies.length &&
        other.hasMoreReplies == hasMoreReplies &&
        other.totalReplyCount == totalReplyCount &&
        other.loadedReplyCount == loadedReplyCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      parentComment,
      replies.length,
      hasMoreReplies,
      totalReplyCount,
      loadedReplyCount,
    );
  }

  @override
  String toString() {
    return 'CommentThread(parentComment: ${parentComment.id}, replies: ${replies.length}, hasMoreReplies: $hasMoreReplies, totalReplyCount: $totalReplyCount, loadedReplyCount: $loadedReplyCount)';
  }
}
