/// Domain entity for challenge participation
///
/// Tracks an individual participant's progress in a challenge
class ChallengeParticipationEntity {
  final String id;
  final String challengeId;
  final String cpId;
  final String groupId;

  // Points & Progress
  final int earnedPoints; // Total points earned from completed tasks
  final List<String> completedTaskIds; // IDs of completed tasks

  // Status
  final ParticipationStatus status;
  final DateTime? completedAt;

  // Tracking
  final DateTime joinedAt;
  final DateTime lastUpdateAt;

  // Ranking
  final int? rank;

  const ChallengeParticipationEntity({
    required this.id,
    required this.challengeId,
    required this.cpId,
    required this.groupId,
    this.earnedPoints = 0,
    this.completedTaskIds = const [],
    this.status = ParticipationStatus.active,
    this.completedAt,
    required this.joinedAt,
    required this.lastUpdateAt,
    this.rank,
  });

  /// Get progress as a percentage (0-100)
  double getProgressPercentage(int totalPossiblePoints) {
    if (totalPossiblePoints == 0) return 0.0;
    final percentage = (earnedPoints / totalPossiblePoints) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Check if participant has completed a specific task
  bool hasCompletedTask(String taskId) {
    return completedTaskIds.contains(taskId);
  }

  /// Check if challenge is completed by this participant
  bool isCompleted() {
    return status == ParticipationStatus.completed;
  }

  /// Check if participant has quit
  bool hasQuit() {
    return status == ParticipationStatus.quit;
  }

  ChallengeParticipationEntity copyWith({
    String? id,
    String? challengeId,
    String? cpId,
    String? groupId,
    int? earnedPoints,
    List<String>? completedTaskIds,
    ParticipationStatus? status,
    DateTime? completedAt,
    DateTime? joinedAt,
    DateTime? lastUpdateAt,
    int? rank,
  }) {
    return ChallengeParticipationEntity(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      cpId: cpId ?? this.cpId,
      groupId: groupId ?? this.groupId,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      joinedAt: joinedAt ?? this.joinedAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      rank: rank ?? this.rank,
    );
  }
}

/// Participation status
enum ParticipationStatus {
  active, // Currently participating
  completed, // Successfully completed
  failed, // Did not complete in time
  quit, // Voluntarily quit
}

/// Extension for string conversion
extension ParticipationStatusExtension on ParticipationStatus {
  String toFirestore() {
    switch (this) {
      case ParticipationStatus.active:
        return 'active';
      case ParticipationStatus.completed:
        return 'completed';
      case ParticipationStatus.failed:
        return 'failed';
      case ParticipationStatus.quit:
        return 'quit';
    }
  }

  static ParticipationStatus fromFirestore(String value) {
    switch (value) {
      case 'active':
        return ParticipationStatus.active;
      case 'completed':
        return ParticipationStatus.completed;
      case 'failed':
        return ParticipationStatus.failed;
      case 'quit':
        return ParticipationStatus.quit;
      default:
        return ParticipationStatus.active;
    }
  }
}

