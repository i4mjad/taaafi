/// Domain entity for group chat messages
///
/// Represents a message in a group chat following the schema specification
/// from F3_Support_Groups_Collections_and_Schema.md
class GroupMessageEntity {
  final String id;
  final String groupId;
  final String senderCpId;
  final String body;
  final String? replyToMessageId;
  final String? quotedPreview;
  final List<String> mentions;
  final List<String> mentionHandles;
  final List<String> tokens;
  final bool isDeleted;
  final bool isHidden;
  final ModerationStatus moderation;
  final DateTime createdAt;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  const GroupMessageEntity({
    required this.id,
    required this.groupId,
    required this.senderCpId,
    required this.body,
    this.replyToMessageId,
    this.quotedPreview,
    this.mentions = const [],
    this.mentionHandles = const [],
    this.tokens = const [],
    this.isDeleted = false,
    this.isHidden = false,
    this.moderation = const ModerationStatus(),
    required this.createdAt,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
  });

  GroupMessageEntity copyWith({
    String? id,
    String? groupId,
    String? senderCpId,
    String? body,
    String? replyToMessageId,
    String? quotedPreview,
    List<String>? mentions,
    List<String>? mentionHandles,
    List<String>? tokens,
    bool? isDeleted,
    bool? isHidden,
    ModerationStatus? moderation,
    DateTime? createdAt,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
  }) {
    return GroupMessageEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderCpId: senderCpId ?? this.senderCpId,
      body: body ?? this.body,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      quotedPreview: quotedPreview ?? this.quotedPreview,
      mentions: mentions ?? this.mentions,
      mentionHandles: mentionHandles ?? this.mentionHandles,
      tokens: tokens ?? this.tokens,
      isDeleted: isDeleted ?? this.isDeleted,
      isHidden: isHidden ?? this.isHidden,
      moderation: moderation ?? this.moderation,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
    );
  }

  /// Helper to check if message is visible (not deleted/hidden/blocked)
  bool get isVisible =>
      !isDeleted &&
      !isHidden &&
      moderation.status != ModerationStatusType.blocked;

  /// Helper to get display body (empty if not visible)
  String get displayBody => isVisible ? body : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMessageEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupMessageEntity{id: $id, groupId: $groupId, senderCpId: $senderCpId, body: ${body.length} chars}';
  }
}

/// Moderation status for messages following schema specification
class ModerationStatus {
  final ModerationStatusType status;
  final String? reason;

  const ModerationStatus({
    this.status = ModerationStatusType.pending,
    this.reason,
  });

  ModerationStatus copyWith({
    ModerationStatusType? status,
    String? reason,
  }) {
    return ModerationStatus(
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      if (reason != null) 'reason': reason,
    };
  }

  factory ModerationStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ModerationStatus();

    return ModerationStatus(
      status: ModerationStatusType.fromString(map['status'] ?? 'pending'),
      reason: map['reason'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModerationStatus &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          reason == other.reason;

  @override
  int get hashCode => status.hashCode ^ reason.hashCode;
}

/// Enumeration for moderation status types
enum ModerationStatusType {
  pending('pending'),
  approved('approved'),
  blocked('blocked'),
  manual_review('manual_review');

  const ModerationStatusType(this.value);

  final String value;

  static ModerationStatusType fromString(String value) {
    switch (value) {
      case 'pending':
        return ModerationStatusType.pending;
      case 'approved':
        return ModerationStatusType.approved;
      case 'blocked':
        return ModerationStatusType.blocked;
      case 'manual_review':
        return ModerationStatusType.manual_review;
      default:
        return ModerationStatusType.pending;
    }
  }
}
