/// Domain entity for comments on group updates
///
/// Represents a comment made on an update in the group feed
class UpdateCommentEntity {
  final String id;
  final String updateId;
  final String groupId;
  final String authorCpId;
  final String content; // Max 500 chars
  final bool isAnonymous;
  final bool isHidden;
  final Map<String, List<String>> reactions; // emoji -> [cpIds]
  final DateTime createdAt;

  const UpdateCommentEntity({
    required this.id,
    required this.updateId,
    required this.groupId,
    required this.authorCpId,
    required this.content,
    this.isAnonymous = false,
    this.isHidden = false,
    this.reactions = const {},
    required this.createdAt,
  });

  /// Get count of reactions for a specific emoji
  int getReactionCount(String emoji) {
    return reactions[emoji]?.length ?? 0;
  }

  /// Check if a specific user has reacted with a specific emoji
  bool hasUserReacted(String cpId, String emoji) {
    return reactions[emoji]?.contains(cpId) ?? false;
  }

  /// Get total count of all reactions
  int getTotalReactions() {
    return reactions.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Check if user can edit this comment
  bool canEdit(String cpId) {
    return authorCpId == cpId;
  }

  /// Check if user can delete this comment
  bool canDelete(String cpId, bool isAdmin) {
    return authorCpId == cpId || isAdmin;
  }

  UpdateCommentEntity copyWith({
    String? id,
    String? updateId,
    String? groupId,
    String? authorCpId,
    String? content,
    bool? isAnonymous,
    bool? isHidden,
    Map<String, List<String>>? reactions,
    DateTime? createdAt,
  }) {
    return UpdateCommentEntity(
      id: id ?? this.id,
      updateId: updateId ?? this.updateId,
      groupId: groupId ?? this.groupId,
      authorCpId: authorCpId ?? this.authorCpId,
      content: content ?? this.content,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isHidden: isHidden ?? this.isHidden,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updateId': updateId,
      'groupId': groupId,
      'authorCpId': authorCpId,
      'content': content,
      'isAnonymous': isAnonymous,
      'isHidden': isHidden,
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

