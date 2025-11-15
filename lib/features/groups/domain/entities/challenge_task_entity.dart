/// Domain entity for challenge tasks
///
/// Represents an individual task within a challenge
class ChallengeTaskEntity {
  final String id;
  final String name;
  final int points;
  final TaskFrequency frequency;
  final int order;

  const ChallengeTaskEntity({
    required this.id,
    required this.name,
    required this.points,
    required this.frequency,
    this.order = 0,
  });

  /// Calculate maximum possible points for this task given challenge duration
  int getMaxPoints(DateTime challengeEndDate) {
    final now = DateTime.now();
    final daysRemaining = challengeEndDate.difference(now).inDays + 1;

    switch (frequency) {
      case TaskFrequency.daily:
        return points * daysRemaining;
      case TaskFrequency.weekly:
        final weeksRemaining = (daysRemaining / 7).ceil();
        return points * weeksRemaining;
      case TaskFrequency.oneTime:
        return points;
    }
  }

  ChallengeTaskEntity copyWith({
    String? id,
    String? name,
    int? points,
    TaskFrequency? frequency,
    int? order,
  }) {
    return ChallengeTaskEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      frequency: frequency ?? this.frequency,
      order: order ?? this.order,
    );
  }
}

/// Task frequency
enum TaskFrequency {
  daily, // Can be completed once per day
  weekly, // Can be completed once per week
  oneTime, // Can be completed only once
}

/// Extension for string conversion
extension TaskFrequencyExtension on TaskFrequency {
  String toFirestore() {
    switch (this) {
      case TaskFrequency.daily:
        return 'daily';
      case TaskFrequency.weekly:
        return 'weekly';
      case TaskFrequency.oneTime:
        return 'one_time';
    }
  }

  static TaskFrequency fromFirestore(String value) {
    switch (value) {
      case 'daily':
        return TaskFrequency.daily;
      case 'weekly':
        return TaskFrequency.weekly;
      case 'one_time':
        return TaskFrequency.oneTime;
      default:
        return TaskFrequency.oneTime;
    }
  }
}

