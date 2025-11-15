import '../../domain/entities/challenge_task_entity.dart';

class ChallengeTaskModel extends ChallengeTaskEntity {
  const ChallengeTaskModel({
    required super.id,
    required super.name,
    required super.points,
    required super.frequency,
    super.order,
  });

  /// Create from Firestore map
  factory ChallengeTaskModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChallengeTaskModel(
      id: id,
      name: data['name'] as String,
      points: data['points'] as int,
      frequency: TaskFrequencyExtension.fromFirestore(data['frequency'] as String),
      order: data['order'] as int? ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'points': points,
      'frequency': frequency.toFirestore(),
      'order': order,
    };
  }

  /// Convert from domain entity to data model
  factory ChallengeTaskModel.fromEntity(ChallengeTaskEntity entity) {
    return ChallengeTaskModel(
      id: entity.id,
      name: entity.name,
      points: entity.points,
      frequency: entity.frequency,
      order: entity.order,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeTaskEntity toEntity() {
    return this;
  }
}

