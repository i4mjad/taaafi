/// Domain entity for group challenges
///
/// Represents a challenge in a support group with all configuration
/// and status information
class ChallengeEntity {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final ChallengeType type;

  // Duration-based fields
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;

  // Goal-based fields
  final GoalType? goalType;
  final int? goalTarget;
  final String? goalUnit;

  // Participation
  final List<String> participants;
  final int participantCount;
  final int? maxParticipants;

  // Status
  final ChallengeStatus status;

  // Metadata
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Settings
  final bool isRecurring;
  final RecurringInterval? recurringInterval;
  final bool allowLateJoin;
  final bool notifyOnMilestone;

  // Rewards
  final String? badgeId;
  final int pointsReward;

  // Privacy
  final ChallengeVisibility visibility;

  const ChallengeEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.goalType,
    this.goalTarget,
    this.goalUnit,
    this.participants = const [],
    this.participantCount = 0,
    this.maxParticipants,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurringInterval,
    this.allowLateJoin = true,
    this.notifyOnMilestone = true,
    this.badgeId,
    this.pointsReward = 0,
    this.visibility = ChallengeVisibility.public,
  });

  /// Check if challenge is currently active
  bool isActive() {
    if (status != ChallengeStatus.active) return false;

    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if new members can join this challenge
  bool canJoin(String cpId) {
    // Check if already a participant
    if (participants.contains(cpId)) return false;

    // Check if challenge is active
    if (status != ChallengeStatus.active) return false;

    // Check if challenge is full
    if (maxParticipants != null && participantCount >= maxParticipants!) {
      return false;
    }

    // Check if challenge has started and late join is not allowed
    final now = DateTime.now();
    if (now.isAfter(startDate) && !allowLateJoin) {
      return false;
    }

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

    final difference = endDate.difference(now);
    return difference.inDays + 1;
  }

  /// Get overall group progress percentage
  /// This would typically be calculated from participant data
  double getProgressPercentage() {
    // This is a placeholder - actual calculation would aggregate participant progress
    // For now, return 0 as it should be calculated with participant data
    return 0.0;
  }

  /// Check if challenge has started
  bool hasStarted() {
    return DateTime.now().isAfter(startDate);
  }

  /// Check if challenge is ending soon (within 3 days)
  bool isEndingSoon() {
    final daysLeft = getDaysRemaining();
    return daysLeft > 0 && daysLeft <= 3;
  }

  /// Check if challenge is full
  bool isFull() {
    if (maxParticipants == null) return false;
    return participantCount >= maxParticipants!;
  }

  ChallengeEntity copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    ChallengeType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    GoalType? goalType,
    int? goalTarget,
    String? goalUnit,
    List<String>? participants,
    int? participantCount,
    int? maxParticipants,
    ChallengeStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    RecurringInterval? recurringInterval,
    bool? allowLateJoin,
    bool? notifyOnMilestone,
    String? badgeId,
    int? pointsReward,
    ChallengeVisibility? visibility,
  }) {
    return ChallengeEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      goalType: goalType ?? this.goalType,
      goalTarget: goalTarget ?? this.goalTarget,
      goalUnit: goalUnit ?? this.goalUnit,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      allowLateJoin: allowLateJoin ?? this.allowLateJoin,
      notifyOnMilestone: notifyOnMilestone ?? this.notifyOnMilestone,
      badgeId: badgeId ?? this.badgeId,
      pointsReward: pointsReward ?? this.pointsReward,
      visibility: visibility ?? this.visibility,
    );
  }
}

/// Challenge types
enum ChallengeType {
  duration, // Complete activity for set number of days
  goal, // Reach a specific target
  team, // Collaborative group goal
  recurring, // Regular check-ins on schedule
}

/// Challenge status
enum ChallengeStatus {
  draft, // Not yet started
  active, // Currently running
  completed, // Finished successfully
  cancelled, // Cancelled by admin
}

/// Goal types for challenges
enum GoalType {
  messages, // Send X messages
  daysActive, // Be active X days
  custom, // Custom metric
}

/// Recurring intervals
enum RecurringInterval {
  daily,
  weekly,
  monthly,
}

/// Challenge visibility
enum ChallengeVisibility {
  public, // Visible to all group members
  private, // Visible only to participants
}

/// Extension for string conversion
extension ChallengeTypeExtension on ChallengeType {
  String toFirestore() {
    switch (this) {
      case ChallengeType.duration:
        return 'duration';
      case ChallengeType.goal:
        return 'goal';
      case ChallengeType.team:
        return 'team';
      case ChallengeType.recurring:
        return 'recurring';
    }
  }

  static ChallengeType fromFirestore(String value) {
    switch (value) {
      case 'duration':
        return ChallengeType.duration;
      case 'goal':
        return ChallengeType.goal;
      case 'team':
        return ChallengeType.team;
      case 'recurring':
        return ChallengeType.recurring;
      default:
        return ChallengeType.duration;
    }
  }
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

extension GoalTypeExtension on GoalType {
  String toFirestore() {
    switch (this) {
      case GoalType.messages:
        return 'messages';
      case GoalType.daysActive:
        return 'days_active';
      case GoalType.custom:
        return 'custom';
    }
  }

  static GoalType fromFirestore(String value) {
    switch (value) {
      case 'messages':
        return GoalType.messages;
      case 'days_active':
        return GoalType.daysActive;
      case 'custom':
        return GoalType.custom;
      default:
        return GoalType.custom;
    }
  }
}

extension RecurringIntervalExtension on RecurringInterval {
  String toFirestore() {
    switch (this) {
      case RecurringInterval.daily:
        return 'daily';
      case RecurringInterval.weekly:
        return 'weekly';
      case RecurringInterval.monthly:
        return 'monthly';
    }
  }

  static RecurringInterval fromFirestore(String value) {
    switch (value) {
      case 'daily':
        return RecurringInterval.daily;
      case 'weekly':
        return RecurringInterval.weekly;
      case 'monthly':
        return RecurringInterval.monthly;
      default:
        return RecurringInterval.weekly;
    }
  }
}

extension ChallengeVisibilityExtension on ChallengeVisibility {
  String toFirestore() {
    switch (this) {
      case ChallengeVisibility.public:
        return 'public';
      case ChallengeVisibility.private:
        return 'private';
    }
  }

  static ChallengeVisibility fromFirestore(String value) {
    switch (value) {
      case 'public':
        return ChallengeVisibility.public;
      case 'private':
        return ChallengeVisibility.private;
      default:
        return ChallengeVisibility.public;
    }
  }
}

