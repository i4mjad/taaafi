import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_entity.dart';

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.description,
    required super.gender,
    required super.memberCapacity,
    required super.adminCpId,
    required super.createdByCpId,
    required super.visibility,
    required super.joinMethod,
    super.joinCodeHash,
    super.joinCodeExpiresAt,
    super.joinCodeMaxUses,
    super.joinCodeUseCount = 0,
    super.isActive = true,
    super.isPaused = false,
    super.pauseReason,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GroupModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      gender: data['gender'] as String,
      memberCapacity: data['memberCapacity'] as int,
      adminCpId: data['adminCpId'] as String,
      createdByCpId: data['createdByCpId'] as String,
      visibility: data['visibility'] as String,
      joinMethod: data['joinMethod'] as String,
      joinCodeHash: data['joinCodeHash'] as String?,
      joinCodeExpiresAt: data['joinCodeExpiresAt'] != null
          ? (data['joinCodeExpiresAt'] as Timestamp).toDate()
          : null,
      joinCodeMaxUses: data['joinCodeMaxUses'] as int?,
      joinCodeUseCount: data['joinCodeUseCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      isPaused: data['isPaused'] as bool? ?? false,
      pauseReason: data['pauseReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'gender': gender,
      'memberCapacity': memberCapacity,
      'adminCpId': adminCpId,
      'createdByCpId': createdByCpId,
      'visibility': visibility,
      'joinMethod': joinMethod,
      'joinCodeHash': joinCodeHash,
      'joinCodeExpiresAt': joinCodeExpiresAt != null
          ? Timestamp.fromDate(joinCodeExpiresAt!)
          : null,
      'joinCodeMaxUses': joinCodeMaxUses,
      'joinCodeUseCount': joinCodeUseCount,
      'isActive': isActive,
      'isPaused': isPaused,
      'pauseReason': pauseReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert from domain entity to data model
  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      gender: entity.gender,
      memberCapacity: entity.memberCapacity,
      adminCpId: entity.adminCpId,
      createdByCpId: entity.createdByCpId,
      visibility: entity.visibility,
      joinMethod: entity.joinMethod,
      joinCodeHash: entity.joinCodeHash,
      joinCodeExpiresAt: entity.joinCodeExpiresAt,
      joinCodeMaxUses: entity.joinCodeMaxUses,
      joinCodeUseCount: entity.joinCodeUseCount,
      isActive: entity.isActive,
      isPaused: entity.isPaused,
      pauseReason: entity.pauseReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to domain entity
  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      description: description,
      gender: gender,
      memberCapacity: memberCapacity,
      adminCpId: adminCpId,
      createdByCpId: createdByCpId,
      visibility: visibility,
      joinMethod: joinMethod,
      joinCodeHash: joinCodeHash,
      joinCodeExpiresAt: joinCodeExpiresAt,
      joinCodeMaxUses: joinCodeMaxUses,
      joinCodeUseCount: joinCodeUseCount,
      isActive: isActive,
      isPaused: isPaused,
      pauseReason: pauseReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
