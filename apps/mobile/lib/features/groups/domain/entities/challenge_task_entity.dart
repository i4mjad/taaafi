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
  final TaskType taskType;

  const ChallengeTaskEntity({
    required this.id,
    required this.name,
    required this.points,
    required this.frequency,
    this.order = 0,
    this.allowRetroactiveCompletion = true, // Default: flexible
    this.taskType = TaskType.manual,
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
    }
  }

  ChallengeTaskEntity copyWith({
    String? id,
    String? name,
    int? points,
    TaskFrequency? frequency,
    int? order,
    bool? allowRetroactiveCompletion,
    TaskType? taskType,
  }) {
    return ChallengeTaskEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      frequency: frequency ?? this.frequency,
      order: order ?? this.order,
      allowRetroactiveCompletion:
          allowRetroactiveCompletion ?? this.allowRetroactiveCompletion,
      taskType: taskType ?? this.taskType,
    );
  }
}

/// Task tracking type
enum TaskType {
  manual, // User manually marks completion
  messageCount, // Auto-tracked when messages are sent
  dailyCheckin, // Auto-tracked from daily activity
}

/// Extension for TaskType string conversion
extension TaskTypeExtension on TaskType {
  String toFirestore() {
    switch (this) {
      case TaskType.manual:
        return 'manual';
      case TaskType.messageCount:
        return 'messageCount';
      case TaskType.dailyCheckin:
        return 'dailyCheckin';
    }
  }

  static TaskType fromFirestore(String value) {
    switch (value) {
      case 'messageCount':
        return TaskType.messageCount;
      case 'dailyCheckin':
        return TaskType.dailyCheckin;
      case 'manual':
      default:
        return TaskType.manual; // Default for backward compatibility
    }
  }
}

/// Task frequency
enum TaskFrequency {
  daily, // Can be completed once per day
  weekly, // Can be completed once per week
}

/// Extension for string conversion
extension TaskFrequencyExtension on TaskFrequency {
  String toFirestore() {
    switch (this) {
      case TaskFrequency.daily:
        return 'daily';
      case TaskFrequency.weekly:
        return 'weekly';
    }
  }

  static TaskFrequency fromFirestore(String value) {
    switch (value) {
      case 'daily':
        return TaskFrequency.daily;
      case 'weekly':
        return TaskFrequency.weekly;
      default:
        return TaskFrequency.daily; // Default to daily for backward compatibility
    }
  }
}

