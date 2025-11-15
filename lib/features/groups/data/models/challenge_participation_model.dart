import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_participation_entity.dart';

class ChallengeParticipationModel extends ChallengeParticipationEntity {
  const ChallengeParticipationModel({
    required super.id,
    required super.challengeId,
    required super.cpId,
    required super.groupId,
    super.progress,
    super.currentValue,
    required super.goalValue,
    super.status,
    super.completedAt,
    required super.joinedAt,
    required super.lastUpdateAt,
    super.dailyLog,
    super.streakCount,
    super.longestStreak,
    super.rank,
    super.points,
  });

  /// Create from Firestore document
  factory ChallengeParticipationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Handle dailyLog conversion
    List<DateTime> dailyLog = [];
    if (data['dailyLog'] != null) {
      final logData = data['dailyLog'] as List;
      dailyLog = logData
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList();
    }

    return ChallengeParticipationModel(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      cpId: data['cpId'] as String,
      groupId: data['groupId'] as String,
      progress: data['progress'] as int? ?? 0,
      currentValue: data['currentValue'] as int? ?? 0,
      goalValue: data['goalValue'] as int,
      status: ParticipationStatusExtension.fromFirestore(
          data['status'] as String),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastUpdateAt: (data['lastUpdateAt'] as Timestamp).toDate(),
      dailyLog: dailyLog,
      streakCount: data['streakCount'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      rank: data['rank'] as int?,
      points: data['points'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'cpId': cpId,
      'groupId': groupId,
      'progress': progress,
      'currentValue': currentValue,
      'goalValue': goalValue,
      'status': status.toFirestore(),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastUpdateAt': Timestamp.fromDate(lastUpdateAt),
      'dailyLog': dailyLog.map((date) => Timestamp.fromDate(date)).toList(),
      'streakCount': streakCount,
      'longestStreak': longestStreak,
      'rank': rank,
      'points': points,
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
      progress: entity.progress,
      currentValue: entity.currentValue,
      goalValue: entity.goalValue,
      status: entity.status,
      completedAt: entity.completedAt,
      joinedAt: entity.joinedAt,
      lastUpdateAt: entity.lastUpdateAt,
      dailyLog: entity.dailyLog,
      streakCount: entity.streakCount,
      longestStreak: entity.longestStreak,
      rank: entity.rank,
      points: entity.points,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeParticipationEntity toEntity() {
    return this;
  }
}

