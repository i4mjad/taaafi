/// Domain entity for challenge tasks
///
/// Represents an individual task within a challenge
class ChallengeTaskEntity {
  final String id;
  final String name;
  final int points;
  final TaskFrequency frequency;
  final int order;
  final bool allowRetroactiveCompletion; // Allow completing after deadline

  const ChallengeTaskEntity({
    required this.id,
    required this.name,
    required this.points,
    required this.frequency,
    this.order = 0,
    this.allowRetroactiveCompletion = true, // Default: flexible
  });

  /// Calculate maximum possible points for this task
  /// Based on challenge total duration (createdAt to endDate)
  int getMaxPoints(DateTime challengeCreatedAt, DateTime challengeEndDate) {
    final totalDays = challengeEndDate.difference(challengeCreatedAt).inDays + 1;

    switch (frequency) {
      case TaskFrequency.daily:
        return points * totalDays;
      case TaskFrequency.weekly:
        final totalWeeks = (totalDays / 7).ceil();
        return points * totalWeeks;
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
    bool? allowRetroactiveCompletion,
  }) {
    return ChallengeTaskEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      frequency: frequency ?? this.frequency,
      order: order ?? this.order,
      allowRetroactiveCompletion:
          allowRetroactiveCompletion ?? this.allowRetroactiveCompletion,
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

