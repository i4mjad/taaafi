import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_entity.dart';

class ChallengeModel extends ChallengeEntity {
  const ChallengeModel({
    required super.id,
    required super.groupId,
    required super.title,
    required super.description,
    required super.type,
    required super.startDate,
    required super.endDate,
    required super.durationDays,
    super.goalType,
    super.goalTarget,
    super.goalUnit,
    super.participants,
    super.participantCount,
    super.maxParticipants,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.isRecurring,
    super.recurringInterval,
    super.allowLateJoin,
    super.notifyOnMilestone,
    super.badgeId,
    super.pointsReward,
    super.visibility,
  });

  /// Create from Firestore document
  factory ChallengeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChallengeModel(
      id: doc.id,
      groupId: data['groupId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      type: ChallengeTypeExtension.fromFirestore(data['type'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      durationDays: data['durationDays'] as int,
      goalType: data['goalType'] != null
          ? GoalTypeExtension.fromFirestore(data['goalType'] as String)
          : null,
      goalTarget: data['goalTarget'] as int?,
      goalUnit: data['goalUnit'] as String?,
      participants: data['participants'] != null
          ? List<String>.from(data['participants'] as List)
          : [],
      participantCount: data['participantCount'] as int? ?? 0,
      maxParticipants: data['maxParticipants'] as int?,
      status:
          ChallengeStatusExtension.fromFirestore(data['status'] as String),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringInterval: data['recurringInterval'] != null
          ? RecurringIntervalExtension.fromFirestore(
              data['recurringInterval'] as String)
          : null,
      allowLateJoin: data['allowLateJoin'] as bool? ?? true,
      notifyOnMilestone: data['notifyOnMilestone'] as bool? ?? true,
      badgeId: data['badgeId'] as String?,
      pointsReward: data['pointsReward'] as int? ?? 0,
      visibility: data['visibility'] != null
          ? ChallengeVisibilityExtension.fromFirestore(
              data['visibility'] as String)
          : ChallengeVisibility.public,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'type': type.toFirestore(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': durationDays,
      'goalType': goalType?.toFirestore(),
      'goalTarget': goalTarget,
      'goalUnit': goalUnit,
      'participants': participants,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'status': status.toFirestore(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval?.toFirestore(),
      'allowLateJoin': allowLateJoin,
      'notifyOnMilestone': notifyOnMilestone,
      'badgeId': badgeId,
      'pointsReward': pointsReward,
      'visibility': visibility.toFirestore(),
    };
  }

  /// Convert from domain entity to data model
  factory ChallengeModel.fromEntity(ChallengeEntity entity) {
    return ChallengeModel(
      id: entity.id,
      groupId: entity.groupId,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      startDate: entity.startDate,
      endDate: entity.endDate,
      durationDays: entity.durationDays,
      goalType: entity.goalType,
      goalTarget: entity.goalTarget,
      goalUnit: entity.goalUnit,
      participants: entity.participants,
      participantCount: entity.participantCount,
      maxParticipants: entity.maxParticipants,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isRecurring: entity.isRecurring,
      recurringInterval: entity.recurringInterval,
      allowLateJoin: entity.allowLateJoin,
      notifyOnMilestone: entity.notifyOnMilestone,
      badgeId: entity.badgeId,
      pointsReward: entity.pointsReward,
      visibility: entity.visibility,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeEntity toEntity() {
    return this;
  }
}

