import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/challenge_task_entity.dart';
import 'challenge_task_model.dart';

class ChallengeModel extends ChallengeEntity {
  const ChallengeModel({
    required super.id,
    required super.groupId,
    required super.name,
    super.description,
    required super.endDate,
    required super.color,
    super.tasks,
    super.participants,
    super.participantCount,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from Firestore document
  factory ChallengeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Parse tasks array
    List<ChallengeTaskEntity> tasks = [];
    if (data['tasks'] != null) {
      final tasksData = data['tasks'] as List;
      tasks = tasksData
          .asMap()
          .entries
          .map((entry) => ChallengeTaskModel.fromFirestore(
                entry.value as Map<String, dynamic>,
                'task_${entry.key}',
              ))
          .toList();
    }

    return ChallengeModel(
      id: doc.id,
      groupId: data['groupId'] as String,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      endDate: (data['endDate'] as Timestamp).toDate(),
      color: data['color'] as String? ?? 'blue',
      tasks: tasks,
      participants: data['participants'] != null
          ? List<String>.from(data['participants'] as List)
          : [],
      participantCount: data['participantCount'] as int? ?? 0,
      status:
          ChallengeStatusExtension.fromFirestore(data['status'] as String),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'endDate': Timestamp.fromDate(endDate),
      'color': color,
      'tasks': tasks
          .map((task) => ChallengeTaskModel.fromEntity(task).toFirestore())
          .toList(),
      'participants': participants,
      'participantCount': participantCount,
      'status': status.toFirestore(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert from domain entity to data model
  factory ChallengeModel.fromEntity(ChallengeEntity entity) {
    return ChallengeModel(
      id: entity.id,
      groupId: entity.groupId,
      name: entity.name,
      description: entity.description,
      endDate: entity.endDate,
      color: entity.color,
      tasks: entity.tasks,
      participants: entity.participants,
      participantCount: entity.participantCount,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to domain entity (returns self since model extends entity)
  ChallengeEntity toEntity() {
    return this;
  }
}

