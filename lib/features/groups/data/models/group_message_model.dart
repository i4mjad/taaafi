import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_message_entity.dart';

/// Data model for group chat messages
///
/// Handles serialization/deserialization to/from Firestore
/// Maps to GroupMessageEntity for domain layer
class GroupMessageModel {
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
  final Map<String, dynamic> moderation;
  final DateTime createdAt;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  const GroupMessageModel({
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
    this.moderation = const {},
    required this.createdAt,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
  });

  /// Creates a GroupMessageModel from Firestore document
  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupMessageModel(
      id: doc.id,
      groupId: data['groupId'] as String,
      senderCpId: data['senderCpId'] as String,
      body: data['body'] as String,
      replyToMessageId: data['replyToMessageId'] as String?,
      quotedPreview: data['quotedPreview'] as String?,
      mentions: List<String>.from(data['mentions'] ?? []),
      mentionHandles: List<String>.from(data['mentionHandles'] ?? []),
      tokens: List<String>.from(data['tokens'] ?? []),
      isDeleted: data['isDeleted'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      moderation: Map<String, dynamic>.from(data['moderation'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPinned: data['isPinned'] as bool? ?? false,
      pinnedAt: data['pinnedAt'] != null 
          ? (data['pinnedAt'] as Timestamp).toDate() 
          : null,
      pinnedBy: data['pinnedBy'] as String?,
    );
  }

  /// Creates a GroupMessageModel from JSON
  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      senderCpId: json['senderCpId'] as String,
      body: json['body'] as String,
      replyToMessageId: json['replyToMessageId'] as String?,
      quotedPreview: json['quotedPreview'] as String?,
      mentions: List<String>.from(json['mentions'] ?? []),
      mentionHandles: List<String>.from(json['mentionHandles'] ?? []),
      tokens: List<String>.from(json['tokens'] ?? []),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      moderation: Map<String, dynamic>.from(json['moderation'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] != null 
          ? DateTime.parse(json['pinnedAt'] as String) 
          : null,
      pinnedBy: json['pinnedBy'] as String?,
    );
  }

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderCpId': senderCpId,
      'body': body,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (quotedPreview != null) 'quotedPreview': quotedPreview,
      'mentions': mentions,
      'mentionHandles': mentionHandles,
      'tokens': tokens,
      'isDeleted': isDeleted,
      'isHidden': isHidden,
      'moderation': moderation,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
      if (pinnedAt != null) 'pinnedAt': Timestamp.fromDate(pinnedAt!),
      if (pinnedBy != null) 'pinnedBy': pinnedBy,
    };
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderCpId': senderCpId,
      'body': body,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (quotedPreview != null) 'quotedPreview': quotedPreview,
      'mentions': mentions,
      'mentionHandles': mentionHandles,
      'tokens': tokens,
      'isDeleted': isDeleted,
      'isHidden': isHidden,
      'moderation': moderation,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      if (pinnedAt != null) 'pinnedAt': pinnedAt!.toIso8601String(),
      if (pinnedBy != null) 'pinnedBy': pinnedBy,
    };
  }

  /// Converts to domain entity
  GroupMessageEntity toEntity() {
    return GroupMessageEntity(
      id: id,
      groupId: groupId,
      senderCpId: senderCpId,
      body: body,
      replyToMessageId: replyToMessageId,
      quotedPreview: quotedPreview,
      mentions: mentions,
      mentionHandles: mentionHandles,
      tokens: tokens,
      isDeleted: isDeleted,
      isHidden: isHidden,
      moderation: ModerationStatus.fromMap(moderation),
      createdAt: createdAt,
      isPinned: isPinned,
      pinnedAt: pinnedAt,
      pinnedBy: pinnedBy,
    );
  }

  /// Creates from domain entity
  factory GroupMessageModel.fromEntity(GroupMessageEntity entity) {
    return GroupMessageModel(
      id: entity.id,
      groupId: entity.groupId,
      senderCpId: entity.senderCpId,
      body: entity.body,
      replyToMessageId: entity.replyToMessageId,
      quotedPreview: entity.quotedPreview,
      mentions: entity.mentions,
      mentionHandles: entity.mentionHandles,
      tokens: entity.tokens,
      isDeleted: entity.isDeleted,
      isHidden: entity.isHidden,
      moderation: entity.moderation.toMap(),
      createdAt: entity.createdAt,
      isPinned: entity.isPinned,
      pinnedAt: entity.pinnedAt,
      pinnedBy: entity.pinnedBy,
    );
  }

  GroupMessageModel copyWith({
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
    Map<String, dynamic>? moderation,
    DateTime? createdAt,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
  }) {
    return GroupMessageModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupMessageModel{id: $id, groupId: $groupId, senderCpId: $senderCpId, body: ${body.length} chars}';
  }
}
