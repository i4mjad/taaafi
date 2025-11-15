import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_update_entity.dart';

class ChallengeUpdateModel extends ChallengeUpdateEntity {
  const ChallengeUpdateModel({
    required super.id,
    required super.challengeId,
    required super.cpId,
    required super.type,
    required super.message,
    super.value,
    required super.createdAt,
  });

  /// Create from Firestore document
  factory ChallengeUpdateModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChallengeUpdateModel(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      cpId: data['cpId'] as String,
      type: ChallengeUpdateTypeExtension.fromFirestore(data['type'] as String),
      message: data['message'] as String,
      value: data['value'] as int?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'cpId': cpId,
      'type': type.toFirestore(),
      'message': message,
      'value': value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert from domain entity to data model
  factory ChallengeUpdateModel.fromEntity(ChallengeUpdateEntity entity) {
    return ChallengeUpdateModel(
      id: entity.id,
      challengeId: entity.challengeId,
      cpId: entity.cpId,
      type: entity.type,
      message: entity.message,
      value: entity.value,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeUpdateEntity toEntity() {
    return this;
  }
}

