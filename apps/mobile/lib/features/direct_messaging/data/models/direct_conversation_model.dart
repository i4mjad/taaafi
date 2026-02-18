import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/direct_conversation_entity.dart';

/// Firestore model for DirectConversationEntity
class DirectConversationModel extends DirectConversationEntity {
  const DirectConversationModel({
    required super.id,
    required super.participantCpIds,
    super.lastMessage,
    required super.lastActivityAt,
    required super.unreadBy,
    required super.mutedBy,
    required super.archivedBy,
    required super.deletedFor,
    required super.createdAt,
    required super.createdByCpId,
  });

  /// Create from Firestore document
  factory DirectConversationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Handle lastActivityAt - default to createdAt if null
    final lastActivityAtTimestamp = data['lastActivityAt'] as Timestamp?;
    final createdAtTimestamp = data['createdAt'] as Timestamp?;

    return DirectConversationModel(
      id: doc.id,
      participantCpIds: List<String>.from(data['participantCpIds'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastActivityAt: lastActivityAtTimestamp?.toDate() ??
          createdAtTimestamp?.toDate() ??
          DateTime.now(),
      unreadBy: Map<String, int>.from(data['unreadBy'] ?? {}),
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
      archivedBy: List<String>.from(data['archivedBy'] ?? []),
      deletedFor: List<String>.from(data['isDeletedFor'] ?? []),
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      createdByCpId: data['createdByCpId'] as String? ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantCpIds': participantCpIds,
      'lastMessage': lastMessage,
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'unreadBy': unreadBy,
      'mutedBy': mutedBy,
      'archivedBy': archivedBy,
      'isDeletedFor': deletedFor,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByCpId': createdByCpId,
    };
  }

  /// Create from entity
  factory DirectConversationModel.fromEntity(DirectConversationEntity entity) {
    return DirectConversationModel(
      id: entity.id,
      participantCpIds: entity.participantCpIds,
      lastMessage: entity.lastMessage,
      lastActivityAt: entity.lastActivityAt,
      unreadBy: entity.unreadBy,
      mutedBy: entity.mutedBy,
      archivedBy: entity.archivedBy,
      deletedFor: entity.deletedFor,
      createdAt: entity.createdAt,
      createdByCpId: entity.createdByCpId,
    );
  }

  /// Generate deterministic conversation ID from two CP IDs
  static String generateConversationId(String cpId1, String cpId2) {
    // Sort alphabetically to ensure same ID regardless of order
    final sorted = [cpId1, cpId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
