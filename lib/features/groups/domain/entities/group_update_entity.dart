/// Domain entity for group updates (shared progress/status updates in groups)
///
/// Represents an update post in the group feed where members can share
/// their progress, request support, or celebrate milestones
class GroupUpdateEntity {
  final String id;
  final String groupId;
  final String authorCpId;

  // Content
  final UpdateType type;
  final String title; // Max 100 chars
  final String content; // Max 1000 chars

  // Links to other data
  final String? linkedFollowupId; // Link to user's followup entry
  final String? linkedChallengeId; // Link to challenge if relevant
  final String? linkedMilestoneId; // Link to achievement/milestone

  // Metadata
  final bool isAnonymous;
  final UpdateVisibility visibility;

  // Engagement
  final Map<String, List<String>> reactions; // emoji -> [cpIds]
  final int commentCount;
  final int supportCount; // count of support reactions

  // Status
  final bool isPinned;
  final bool isHidden;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupUpdateEntity({
    required this.id,
    required this.groupId,
    required this.authorCpId,
    required this.type,
    required this.title,
    required this.content,
    this.linkedFollowupId,
    this.linkedChallengeId,
    this.linkedMilestoneId,
    this.isAnonymous = false,
    this.visibility = UpdateVisibility.membersOnly,
    this.reactions = const {},
    this.commentCount = 0,
    this.supportCount = 0,
    this.isPinned = false,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
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

  /// Check if user can edit this update
  bool canEdit(String cpId) {
    return authorCpId == cpId;
  }

  /// Check if user can delete this update
  bool canDelete(String cpId, bool isAdmin) {
    return authorCpId == cpId || isAdmin;
  }

  /// Check if update is linked to a followup entry
  bool hasLinkedFollowup() {
    return linkedFollowupId != null;
  }

  /// Check if update is linked to a challenge
  bool hasLinkedChallenge() {
    return linkedChallengeId != null;
  }

  /// Get list of all unique users who reacted
  Set<String> getReactingUsers() {
    final users = <String>{};
    for (final cpIds in reactions.values) {
      users.addAll(cpIds);
    }
    return users;
  }

  /// Get most popular emoji (most reactions)
  String? getMostPopularEmoji() {
    if (reactions.isEmpty) return null;
    
    String? mostPopular;
    int maxCount = 0;
    
    reactions.forEach((emoji, cpIds) {
      if (cpIds.length > maxCount) {
        maxCount = cpIds.length;
        mostPopular = emoji;
      }
    });
    
    return mostPopular;
  }

  GroupUpdateEntity copyWith({
    String? id,
    String? groupId,
    String? authorCpId,
    UpdateType? type,
    String? title,
    String? content,
    String? linkedFollowupId,
    String? linkedChallengeId,
    String? linkedMilestoneId,
    bool? isAnonymous,
    UpdateVisibility? visibility,
    Map<String, List<String>>? reactions,
    int? commentCount,
    int? supportCount,
    bool? isPinned,
    bool? isHidden,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupUpdateEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorCpId: authorCpId ?? this.authorCpId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      linkedFollowupId: linkedFollowupId ?? this.linkedFollowupId,
      linkedChallengeId: linkedChallengeId ?? this.linkedChallengeId,
      linkedMilestoneId: linkedMilestoneId ?? this.linkedMilestoneId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      visibility: visibility ?? this.visibility,
      reactions: reactions ?? this.reactions,
      commentCount: commentCount ?? this.commentCount,
      supportCount: supportCount ?? this.supportCount,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'authorCpId': authorCpId,
      'type': type.toFirestore(),
      'title': title,
      'content': content,
      'linkedFollowupId': linkedFollowupId,
      'linkedChallengeId': linkedChallengeId,
      'linkedMilestoneId': linkedMilestoneId,
      'isAnonymous': isAnonymous,
      'visibility': visibility.toFirestore(),
      'reactions': reactions,
      'commentCount': commentCount,
      'supportCount': supportCount,
      'isPinned': isPinned,
      'isHidden': isHidden,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Type of update
enum UpdateType {
  progress, // General progress update
  milestone, // Achievement/milestone reached
  checkin, // Regular check-in
  general, // General update
  encouragement, // Encouraging others
  needHelp, // Requesting help
  needSupport, // Requesting support
  celebration, // Celebrating success
  struggle, // Sharing struggle
}

extension UpdateTypeExtension on UpdateType {
  String toFirestore() {
    switch (this) {
      case UpdateType.progress:
        return 'progress';
      case UpdateType.milestone:
        return 'milestone';
      case UpdateType.checkin:
        return 'checkin';
      case UpdateType.general:
        return 'general';
      case UpdateType.encouragement:
        return 'encouragement';
      case UpdateType.needHelp:
        return 'need_help';
      case UpdateType.needSupport:
        return 'need_support';
      case UpdateType.celebration:
        return 'celebration';
      case UpdateType.struggle:
        return 'struggle';
    }
  }

  static UpdateType fromFirestore(String value) {
    switch (value) {
      case 'progress':
        return UpdateType.progress;
      case 'milestone':
        return UpdateType.milestone;
      case 'checkin':
        return UpdateType.checkin;
      case 'general':
        return UpdateType.general;
      case 'encouragement':
        return UpdateType.encouragement;
      case 'need_help':
        return UpdateType.needHelp;
      case 'need_support':
        return UpdateType.needSupport;
      case 'celebration':
        return UpdateType.celebration;
      case 'struggle':
        return UpdateType.struggle;
      default:
        return UpdateType.general;
    }
  }

  /// Get icon for update type (for UI)
  String get icon {
    switch (this) {
      case UpdateType.progress:
        return '📈';
      case UpdateType.milestone:
        return '🏆';
      case UpdateType.checkin:
        return '✅';
      case UpdateType.general:
        return '💬';
      case UpdateType.encouragement:
        return '💪';
      case UpdateType.needHelp:
        return '🆘';
      case UpdateType.needSupport:
        return '🤝';
      case UpdateType.celebration:
        return '🎉';
      case UpdateType.struggle:
        return '😔';
    }
  }
}

/// Visibility of update
enum UpdateVisibility {
  public, // Visible to everyone
  membersOnly, // Visible to group members only
}

extension UpdateVisibilityExtension on UpdateVisibility {
  String toFirestore() {
    switch (this) {
      case UpdateVisibility.public:
        return 'public';
      case UpdateVisibility.membersOnly:
        return 'members_only';
    }
  }

  static UpdateVisibility fromFirestore(String value) {
    switch (value) {
      case 'public':
        return UpdateVisibility.public;
      case 'members_only':
        return UpdateVisibility.membersOnly;
      default:
        return UpdateVisibility.membersOnly;
    }
  }
}

