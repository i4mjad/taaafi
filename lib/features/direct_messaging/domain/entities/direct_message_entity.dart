import 'package:cloud_firestore/cloud_firestore.dart';

/// Moderation status for direct messages
enum ModerationStatusType {
  pending,
  approved,
  blocked,
}

/// Moderation metadata
class ModerationStatus {
  final ModerationStatusType status;
  final String? reason;

  const ModerationStatus({
    required this.status,
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
}

/// Entity representing a direct message
class DirectMessageEntity {
  final String id;
  final String conversationId;
  final String senderCpId;
  final String body;
  final String? replyToMessageId;
  final String? quotedPreview;
  final List<String> mentions; // cpIds mentioned in message
  final List<String> tokens; // Search tokens (Arabic-aware)
  final bool isDeleted;
  final bool isHidden;
  final ModerationStatus moderation;
  final DateTime createdAt;

  const DirectMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderCpId,
    required this.body,
    this.replyToMessageId,
    this.quotedPreview,
    this.mentions = const [],
    this.tokens = const [],
    this.isDeleted = false,
    this.isHidden = false,
    required this.moderation,
    required this.createdAt,
  });

  /// Check if message is a reply
  bool get isReply => replyToMessageId != null;

  /// Check if message is visible (not deleted/hidden/blocked)
  bool get isVisible =>
      !isDeleted &&
      !isHidden &&
      moderation.status != ModerationStatusType.blocked;

  DirectMessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderCpId,
    String? body,
    String? replyToMessageId,
    String? quotedPreview,
    List<String>? mentions,
    List<String>? tokens,
    bool? isDeleted,
    bool? isHidden,
    ModerationStatus? moderation,
    DateTime? createdAt,
  }) {
    return DirectMessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderCpId: senderCpId ?? this.senderCpId,
      body: body ?? this.body,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      quotedPreview: quotedPreview ?? this.quotedPreview,
      mentions: mentions ?? this.mentions,
      tokens: tokens ?? this.tokens,
      isDeleted: isDeleted ?? this.isDeleted,
      isHidden: isHidden ?? this.isHidden,
      moderation: moderation ?? this.moderation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


