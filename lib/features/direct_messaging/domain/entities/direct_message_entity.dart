/// Moderation status for direct messages
enum ModerationStatusType {
  pending,
  approved,
  blocked,
  manual_review,
}

/// Moderation metadata
class ModerationStatus {
  final ModerationStatusType status;
  final String? reason;
  final int? confidence; // 0-100 confidence score

  const ModerationStatus({
    required this.status,
    this.reason,
    this.confidence,
  });

  ModerationStatus copyWith({
    ModerationStatusType? status,
    String? reason,
    int? confidence,
  }) {
    return ModerationStatus(
      status: status ?? this.status,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
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
  /// This is a basic check - use isVisibleToUser() for user-specific visibility
  bool get isVisible {
    if (isDeleted || isHidden) return false;
    if (moderation.status == ModerationStatusType.blocked) return false;
    if (moderation.status == ModerationStatusType.pending) return false;
    return true;
  }
  
  /// Check if message is visible to a specific user
  /// Recipients can't see high-confidence flagged messages, but senders can
  bool isVisibleToUser(String viewerCpId) {
    // Basic visibility checks
    if (isDeleted || isHidden) return false;
    if (moderation.status == ModerationStatusType.blocked) return false;
    if (moderation.status == ModerationStatusType.pending) return false;
    
    // For manual_review with high confidence, hide from recipients but show to sender
    if (moderation.status == ModerationStatusType.manual_review) {
      final confidence = (moderation.confidence ?? 0) / 100.0;
      final normalizedConfidence = confidence > 1.5 ? confidence / 100.0 : confidence;
      
      if (normalizedConfidence >= 0.85) {
        // High confidence - only visible to sender
        return viewerCpId == senderCpId;
      }
    }
    
    return true;
  }
  
  /// Check if message should show "under review" indicator
  bool get isUnderHighConfidenceReview {
    if (moderation.status != ModerationStatusType.manual_review) return false;
    final confidence = (moderation.confidence ?? 0) / 100.0;
    final normalizedConfidence = confidence > 1.5 ? confidence / 100.0 : confidence;
    return normalizedConfidence >= 0.85;
  }

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


