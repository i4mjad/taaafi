import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_update_entity.dart';

/// Firestore model for group updates
class GroupUpdateModel {
  final String id;
  final String groupId;
  final String authorCpId;
  final String type;
  final String title;
  final String content;
  final String? linkedFollowupId;
  final String? linkedChallengeId;
  final String? linkedMilestoneId;
  final bool isAnonymous;
  final String visibility;
  final Map<String, dynamic> reactions;
  final int commentCount;
  final int supportCount;
  final bool isPinned;
  final bool isHidden;
  final String locale;
  final Map<String, dynamic>? moderation;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const GroupUpdateModel({
    required this.id,
    required this.groupId,
    required this.authorCpId,
    required this.type,
    required this.title,
    required this.content,
    this.linkedFollowupId,
    this.linkedChallengeId,
    this.linkedMilestoneId,
    required this.isAnonymous,
    required this.visibility,
    required this.reactions,
    required this.commentCount,
    required this.supportCount,
    required this.isPinned,
    required this.isHidden,
    required this.locale,
    this.moderation,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create model from Firestore document
  factory GroupUpdateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return GroupUpdateModel(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      authorCpId: data['authorCpId'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      linkedFollowupId: data['linkedFollowupId'] as String?,
      linkedChallengeId: data['linkedChallengeId'] as String?,
      linkedMilestoneId: data['linkedMilestoneId'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      visibility: data['visibility'] as String? ?? 'members_only',
      reactions: _parseReactions(data['reactions']),
      commentCount: data['commentCount'] as int? ?? 0,
      supportCount: data['supportCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      locale: data['locale'] as String? ?? 'en',
      moderation: data['moderation'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'authorCpId': authorCpId,
      'type': type,
      'title': title,
      'content': content,
      'linkedFollowupId': linkedFollowupId,
      'linkedChallengeId': linkedChallengeId,
      'linkedMilestoneId': linkedMilestoneId,
      'isAnonymous': isAnonymous,
      'visibility': visibility,
      'reactions': reactions,
      'commentCount': commentCount,
      'supportCount': supportCount,
      'isPinned': isPinned,
      'isHidden': isHidden,
      'locale': locale,
      'moderation': moderation,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert model to entity
  GroupUpdateEntity toEntity() {
    return GroupUpdateEntity(
      id: id,
      groupId: groupId,
      authorCpId: authorCpId,
      type: UpdateTypeExtension.fromFirestore(type),
      title: title,
      content: content,
      linkedFollowupId: linkedFollowupId,
      linkedChallengeId: linkedChallengeId,
      linkedMilestoneId: linkedMilestoneId,
      isAnonymous: isAnonymous,
      visibility: UpdateVisibilityExtension.fromFirestore(visibility),
      reactions: _parseReactionsToEntity(reactions),
      commentCount: commentCount,
      supportCount: supportCount,
      isPinned: isPinned,
      isHidden: isHidden,
      locale: locale,
      moderation: moderation != null 
          ? ModerationStatus.fromJson(moderation!)
          : null,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }

  /// Create model from entity
  factory GroupUpdateModel.fromEntity(GroupUpdateEntity entity) {
    return GroupUpdateModel(
      id: entity.id,
      groupId: entity.groupId,
      authorCpId: entity.authorCpId,
      type: entity.type.toFirestore(),
      title: entity.title,
      content: entity.content,
      linkedFollowupId: entity.linkedFollowupId,
      linkedChallengeId: entity.linkedChallengeId,
      linkedMilestoneId: entity.linkedMilestoneId,
      isAnonymous: entity.isAnonymous,
      visibility: entity.visibility.toFirestore(),
      reactions: _parseReactionsFromEntity(entity.reactions),
      commentCount: entity.commentCount,
      supportCount: entity.supportCount,
      isPinned: entity.isPinned,
      isHidden: entity.isHidden,
      locale: entity.locale,
      moderation: entity.moderation?.toJson(),
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: Timestamp.fromDate(entity.updatedAt),
    );
  }

  /// Parse reactions from Firestore format to model format
  static Map<String, dynamic> _parseReactions(dynamic reactionsData) {
    if (reactionsData == null) return {};
    if (reactionsData is Map) {
      final result = <String, dynamic>{};
      reactionsData.forEach((key, value) {
        if (value is List) {
          result[key.toString()] = List<String>.from(value);
        }
      });
      return result;
    }
    return {};
  }

  /// Parse reactions from model format to entity format
  static Map<String, List<String>> _parseReactionsToEntity(
    Map<String, dynamic> reactions,
  ) {
    final result = <String, List<String>>{};
    reactions.forEach((key, value) {
      if (value is List) {
        result[key] = List<String>.from(value);
      }
    });
    return result;
  }

  /// Parse reactions from entity format to model format
  static Map<String, dynamic> _parseReactionsFromEntity(
    Map<String, List<String>> reactions,
  ) {
    return Map<String, dynamic>.from(reactions);
  }
}
