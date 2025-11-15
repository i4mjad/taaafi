import 'challenge_task_entity.dart';

/// Domain entity for group challenges
///
/// Represents a challenge in a support group with tasks
class ChallengeEntity {
  final String id;
  final String groupId;
  final String name;
  final DateTime endDate;
  final String color; // 'yellow', 'coral', 'blue', 'teal'
  final List<ChallengeTaskEntity> tasks;

  // Participation
  final List<String> participants;
  final int participantCount;

  // Status
  final ChallengeStatus status;

  // Metadata
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChallengeEntity({
    required this.id,
    required this.groupId,
    required this.name,
    required this.endDate,
    required this.color,
    this.tasks = const [],
    this.participants = const [],
    this.participantCount = 0,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if challenge is currently active
  bool isActive() {
    if (status != ChallengeStatus.active) return false;
    return DateTime.now().isBefore(endDate);
  }

  /// Check if new members can join this challenge
  bool canJoin(String cpId) {
    if (participants.contains(cpId)) return false;
    if (status != ChallengeStatus.active) return false;
    return true;
  }

  /// Check if challenge is completed
  bool isCompleted() {
    return status == ChallengeStatus.completed;
  }

  /// Get number of days remaining in challenge
  int getDaysRemaining() {
    if (isCompleted()) return 0;
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  /// Check if challenge is ending soon (within 3 days)
  bool isEndingSoon() {
    final daysLeft = getDaysRemaining();
    return daysLeft > 0 && daysLeft <= 3;
  }

  /// Get total possible points from all tasks
  int getTotalPossiblePoints() {
    return tasks.fold(0, (sum, task) => sum + task.getMaxPoints(createdAt, endDate));
  }

  ChallengeEntity copyWith({
    String? id,
    String? groupId,
    String? name,
    DateTime? endDate,
    String? color,
    List<ChallengeTaskEntity>? tasks,
    List<String>? participants,
    int? participantCount,
    ChallengeStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChallengeEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Challenge status
enum ChallengeStatus {
  draft, // Not yet started
  active, // Currently running
  completed, // Finished successfully
  cancelled, // Cancelled by admin
}

extension ChallengeStatusExtension on ChallengeStatus {
  String toFirestore() {
    switch (this) {
      case ChallengeStatus.draft:
        return 'draft';
      case ChallengeStatus.active:
        return 'active';
      case ChallengeStatus.completed:
        return 'completed';
      case ChallengeStatus.cancelled:
        return 'cancelled';
    }
  }

  static ChallengeStatus fromFirestore(String value) {
    switch (value) {
      case 'draft':
        return ChallengeStatus.draft;
      case 'active':
        return ChallengeStatus.active;
      case 'completed':
        return ChallengeStatus.completed;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.draft;
    }
  }
}


