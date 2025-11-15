import 'challenge_participation_entity.dart';

/// Domain entity for challenge statistics
///
/// Aggregated stats for a challenge
class ChallengeStatsEntity {
  final String challengeId;
  final int participantCount;
  final int activeParticipantCount;
  final int completedParticipantCount;
  final double completionRate; // Percentage
  final double averageProgress; // Average progress across all participants
  final List<ChallengeParticipationEntity> topParticipants;
  final DateTime lastCalculatedAt;

  const ChallengeStatsEntity({
    required this.challengeId,
    required this.participantCount,
    required this.activeParticipantCount,
    required this.completedParticipantCount,
    required this.completionRate,
    required this.averageProgress,
    this.topParticipants = const [],
    required this.lastCalculatedAt,
  });

  ChallengeStatsEntity copyWith({
    String? challengeId,
    int? participantCount,
    int? activeParticipantCount,
    int? completedParticipantCount,
    double? completionRate,
    double? averageProgress,
    List<ChallengeParticipationEntity>? topParticipants,
    DateTime? lastCalculatedAt,
  }) {
    return ChallengeStatsEntity(
      challengeId: challengeId ?? this.challengeId,
      participantCount: participantCount ?? this.participantCount,
      activeParticipantCount:
          activeParticipantCount ?? this.activeParticipantCount,
      completedParticipantCount:
          completedParticipantCount ?? this.completedParticipantCount,
      completionRate: completionRate ?? this.completionRate,
      averageProgress: averageProgress ?? this.averageProgress,
      topParticipants: topParticipants ?? this.topParticipants,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }
}

