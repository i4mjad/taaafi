import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/direct_message_entity.dart';

/// Firestore model for DirectMessageEntity
class DirectMessageModel extends DirectMessageEntity {
  const DirectMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderCpId,
    required super.body,
    super.replyToMessageId,
    super.quotedPreview,
    super.mentions,
    super.tokens,
    super.isDeleted,
    super.isHidden,
    required super.moderation,
    required super.createdAt,
  });

  /// Create from Firestore document
  factory DirectMessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final moderationData = data['moderation'] as Map<String, dynamic>? ?? {};
    
    return DirectMessageModel(
      id: doc.id,
      conversationId: data['conversationId'] as String,
      senderCpId: data['senderCpId'] as String,
      body: data['body'] as String,
      replyToMessageId: data['replyToMessageId'] as String?,
      quotedPreview: data['quotedPreview'] as String?,
      mentions: List<String>.from(data['mentions'] ?? []),
      tokens: List<String>.from(data['tokens'] ?? []),
      isDeleted: data['isDeleted'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      moderation: ModerationStatus(
        status: _parseModerationStatus(moderationData['status'] as String?),
        reason: moderationData['reason'] as String?,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderCpId': senderCpId,
      'body': body,
      'replyToMessageId': replyToMessageId,
      'quotedPreview': quotedPreview,
      'mentions': mentions,
      'tokens': tokens,
      'isDeleted': isDeleted,
      'isHidden': isHidden,
      'moderation': {
        'status': _moderationStatusToString(moderation.status),
        'reason': moderation.reason,
      },
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from entity
  factory DirectMessageModel.fromEntity(DirectMessageEntity entity) {
    return DirectMessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderCpId: entity.senderCpId,
      body: entity.body,
      replyToMessageId: entity.replyToMessageId,
      quotedPreview: entity.quotedPreview,
      mentions: entity.mentions,
      tokens: entity.tokens,
      isDeleted: entity.isDeleted,
      isHidden: entity.isHidden,
      moderation: entity.moderation,
      createdAt: entity.createdAt,
    );
  }

  /// Parse moderation status from string
  static ModerationStatusType _parseModerationStatus(String? status) {
    switch (status) {
      case 'pending':
        return ModerationStatusType.pending;
      case 'blocked':
        return ModerationStatusType.blocked;
      case 'approved':
      default:
        return ModerationStatusType.approved;
    }
  }

  /// Convert moderation status to string
  static String _moderationStatusToString(ModerationStatusType status) {
    switch (status) {
      case ModerationStatusType.pending:
        return 'pending';
      case ModerationStatusType.approved:
        return 'approved';
      case ModerationStatusType.blocked:
        return 'blocked';
    }
  }
}


