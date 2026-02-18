/// Domain entity for challenge updates/feed
///
/// Represents activity updates in a challenge (progress, milestones, completions)
class ChallengeUpdateEntity {
  final String id;
  final String challengeId;
  final String cpId;
  final ChallengeUpdateType type;
  final String message;
  final int? value; // For progress updates
  final DateTime createdAt;

  const ChallengeUpdateEntity({
    required this.id,
    required this.challengeId,
    required this.cpId,
    required this.type,
    required this.message,
    this.value,
    required this.createdAt,
  });

  ChallengeUpdateEntity copyWith({
    String? id,
    String? challengeId,
    String? cpId,
    ChallengeUpdateType? type,
    String? message,
    int? value,
    DateTime? createdAt,
  }) {
    return ChallengeUpdateEntity(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      cpId: cpId ?? this.cpId,
      type: type ?? this.type,
      message: message ?? this.message,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Types of challenge updates
enum ChallengeUpdateType {
  progress, // Progress update
  milestone, // Milestone reached (25%, 50%, 75%, 100%)
  completion, // Challenge completed
  comment, // User comment/note
}

/// Extension for string conversion
extension ChallengeUpdateTypeExtension on ChallengeUpdateType {
  String toFirestore() {
    switch (this) {
      case ChallengeUpdateType.progress:
        return 'progress';
      case ChallengeUpdateType.milestone:
        return 'milestone';
      case ChallengeUpdateType.completion:
        return 'completion';
      case ChallengeUpdateType.comment:
        return 'comment';
    }
  }

  static ChallengeUpdateType fromFirestore(String value) {
    switch (value) {
      case 'progress':
        return ChallengeUpdateType.progress;
      case 'milestone':
        return ChallengeUpdateType.milestone;
      case 'completion':
        return ChallengeUpdateType.completion;
      case 'comment':
        return ChallengeUpdateType.comment;
      default:
        return ChallengeUpdateType.progress;
    }
  }
}

