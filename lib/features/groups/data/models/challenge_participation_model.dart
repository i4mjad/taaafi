import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_participation_entity.dart';
import '../../domain/entities/task_completion_record_entity.dart';

class ChallengeParticipationModel extends ChallengeParticipationEntity {
  const ChallengeParticipationModel({
    required super.id,
    required super.challengeId,
    required super.cpId,
    required super.groupId,
    super.earnedPoints,
    super.taskCompletions,
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

    // Parse task completions
    List<TaskCompletionRecord> completions = [];
    if (data['taskCompletions'] != null) {
      final completionsData = data['taskCompletions'] as List;
      completions = completionsData
          .map((item) => TaskCompletionRecord.fromFirestore(item as Map<String, dynamic>))
          .toList();
    }

    return ChallengeParticipationModel(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      cpId: data['cpId'] as String,
      groupId: data['groupId'] as String,
      earnedPoints: data['earnedPoints'] as int? ?? 0,
      taskCompletions: completions,
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
      'taskCompletions': taskCompletions.map((c) => c.toFirestore()).toList(),
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
      taskCompletions: entity.taskCompletions,
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

