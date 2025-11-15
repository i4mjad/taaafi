import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_participation_entity.dart';

class ChallengeParticipationModel extends ChallengeParticipationEntity {
  const ChallengeParticipationModel({
    required super.id,
    required super.challengeId,
    required super.cpId,
    required super.groupId,
    super.earnedPoints,
    super.completedTaskIds,
    super.status,
    super.completedAt,
    required super.joinedAt,
    required super.lastUpdateAt,
    super.rank,
  });

  /// Create from Firestore document
  factory ChallengeParticipationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return ChallengeParticipationModel(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      cpId: data['cpId'] as String,
      groupId: data['groupId'] as String,
      earnedPoints: data['earnedPoints'] as int? ?? 0,
      completedTaskIds: data['completedTaskIds'] != null
          ? List<String>.from(data['completedTaskIds'] as List)
          : [],
      status: ParticipationStatusExtension.fromFirestore(
          data['status'] as String),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastUpdateAt: (data['lastUpdateAt'] as Timestamp).toDate(),
      rank: data['rank'] as int?,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'cpId': cpId,
      'groupId': groupId,
      'earnedPoints': earnedPoints,
      'completedTaskIds': completedTaskIds,
      'status': status.toFirestore(),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastUpdateAt': Timestamp.fromDate(lastUpdateAt),
      'rank': rank,
    };
  }

  /// Convert from domain entity to data model
  factory ChallengeParticipationModel.fromEntity(
      ChallengeParticipationEntity entity) {
    return ChallengeParticipationModel(
      id: entity.id,
      challengeId: entity.challengeId,
      cpId: entity.cpId,
      groupId: entity.groupId,
      earnedPoints: entity.earnedPoints,
      completedTaskIds: entity.completedTaskIds,
      status: entity.status,
      completedAt: entity.completedAt,
      joinedAt: entity.joinedAt,
      lastUpdateAt: entity.lastUpdateAt,
      rank: entity.rank,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeParticipationEntity toEntity() {
    return this;
  }
}

