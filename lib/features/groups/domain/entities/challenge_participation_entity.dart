/// Domain entity for challenge participation
///
/// Tracks an individual participant's progress in a challenge
class ChallengeParticipationEntity {
  final String id;
  final String challengeId;
  final String cpId;
  final String groupId;

  // Progress
  final int progress; // 0-100 percentage or absolute value
  final int currentValue; // e.g., 5 days completed out of 30
  final int goalValue; // e.g., 30 days

  // Status
  final ParticipationStatus status;
  final DateTime? completedAt;

  // Tracking
  final DateTime joinedAt;
  final DateTime lastUpdateAt;

  // Daily tracking (for streaks)
  final List<DateTime> dailyLog; // dates of activity
  final int streakCount;
  final int longestStreak;

  // Ranking
  final int? rank;
  final int points;

  const ChallengeParticipationEntity({
    required this.id,
    required this.challengeId,
    required this.cpId,
    required this.groupId,
    this.progress = 0,
    this.currentValue = 0,
    required this.goalValue,
    this.status = ParticipationStatus.active,
    this.completedAt,
    required this.joinedAt,
    required this.lastUpdateAt,
    this.dailyLog = const [],
    this.streakCount = 0,
    this.longestStreak = 0,
    this.rank,
    this.points = 0,
  });

  /// Get progress as a percentage (0-100)
  double getProgressPercentage() {
    if (goalValue == 0) return 0.0;
    final percentage = (currentValue / goalValue) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Check if participant is on track to complete the challenge
  /// Requires challenge entity to calculate expected progress
  bool isOnTrack(DateTime challengeEndDate, DateTime challengeStartDate) {
    final now = DateTime.now();
    final totalDuration = challengeEndDate.difference(challengeStartDate).inDays;
    final elapsedDays = now.difference(challengeStartDate).inDays;

    if (totalDuration == 0) return true;

    final expectedProgress = (elapsedDays / totalDuration) * 100;
    final actualProgress = getProgressPercentage();

    // Allow 10% margin
    return actualProgress >= (expectedProgress - 10);
  }

  /// Check if participant can update progress
  bool canUpdateProgress() {
    return status == ParticipationStatus.active;
  }

  /// Check if challenge is completed by this participant
  bool isCompleted() {
    return status == ParticipationStatus.completed;
  }

  /// Check if participant has quit
  bool hasQuit() {
    return status == ParticipationStatus.quit;
  }

  /// Check if participant has failed
  bool hasFailed() {
    return status == ParticipationStatus.failed;
  }

  /// Get current streak (consecutive days)
  int getCurrentStreak() {
    if (dailyLog.isEmpty) return 0;

    final sortedLog = List<DateTime>.from(dailyLog)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime expectedDate = DateTime.now();

    for (final date in sortedLog) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final expectedOnly =
          DateTime(expectedDate.year, expectedDate.month, expectedDate.day);

      if (dateOnly.isAtSameMomentAs(expectedOnly) ||
          dateOnly.isAtSameMomentAs(
              expectedOnly.subtract(const Duration(days: 1)))) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Check if updated today
  bool hasUpdatedToday() {
    if (dailyLog.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final date in dailyLog) {
      final logDate = DateTime(date.year, date.month, date.day);
      if (logDate.isAtSameMomentAs(today)) {
        return true;
      }
    }

    return false;
  }

  ChallengeParticipationEntity copyWith({
    String? id,
    String? challengeId,
    String? cpId,
    String? groupId,
    int? progress,
    int? currentValue,
    int? goalValue,
    ParticipationStatus? status,
    DateTime? completedAt,
    DateTime? joinedAt,
    DateTime? lastUpdateAt,
    List<DateTime>? dailyLog,
    int? streakCount,
    int? longestStreak,
    int? rank,
    int? points,
  }) {
    return ChallengeParticipationEntity(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      cpId: cpId ?? this.cpId,
      groupId: groupId ?? this.groupId,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      goalValue: goalValue ?? this.goalValue,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      joinedAt: joinedAt ?? this.joinedAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      dailyLog: dailyLog ?? this.dailyLog,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      rank: rank ?? this.rank,
      points: points ?? this.points,
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

