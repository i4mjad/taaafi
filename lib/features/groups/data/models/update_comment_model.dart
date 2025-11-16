import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/update_comment_entity.dart';

/// Firestore model for update comments
class UpdateCommentModel {
  final String id;
  final String updateId;
  final String groupId;
  final String authorCpId;
  final String content;
  final bool isAnonymous;
  final bool isHidden;
  final Map<String, dynamic> reactions;
  final Timestamp createdAt;

  const UpdateCommentModel({
    required this.id,
    required this.updateId,
    required this.groupId,
    required this.authorCpId,
    required this.content,
    required this.isAnonymous,
    required this.isHidden,
    required this.reactions,
    required this.createdAt,
  });

  /// Create model from Firestore document
  factory UpdateCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UpdateCommentModel(
      id: doc.id,
      updateId: data['updateId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      authorCpId: data['authorCpId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      reactions: _parseReactions(data['reactions']),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'updateId': updateId,
      'groupId': groupId,
      'authorCpId': authorCpId,
      'content': content,
      'isAnonymous': isAnonymous,
      'isHidden': isHidden,
      'reactions': reactions,
      'createdAt': createdAt,
    };
  }

  /// Convert model to entity
  UpdateCommentEntity toEntity() {
    return UpdateCommentEntity(
      id: id,
      updateId: updateId,
      groupId: groupId,
      authorCpId: authorCpId,
      content: content,
      isAnonymous: isAnonymous,
      isHidden: isHidden,
      reactions: _parseReactionsToEntity(reactions),
      createdAt: createdAt.toDate(),
    );
  }

  /// Create model from entity
  factory UpdateCommentModel.fromEntity(UpdateCommentEntity entity) {
    return UpdateCommentModel(
      id: entity.id,
      updateId: entity.updateId,
      groupId: entity.groupId,
      authorCpId: entity.authorCpId,
      content: entity.content,
      isAnonymous: entity.isAnonymous,
      isHidden: entity.isHidden,
      reactions: _parseReactionsFromEntity(entity.reactions),
      createdAt: Timestamp.fromDate(entity.createdAt),
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

