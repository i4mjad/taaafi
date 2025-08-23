import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_membership_entity.dart';

class GroupMembershipModel extends GroupMembershipEntity {
  const GroupMembershipModel({
    required super.id,
    required super.groupId,
    required super.cpId,
    required super.role,
    super.isActive = true,
    required super.joinedAt,
    super.leftAt,
    super.pointsTotal = 0,
  });

  /// Create from Firestore document
  factory GroupMembershipModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GroupMembershipModel(
      id: doc.id,
      groupId: data['groupId'] as String,
      cpId: data['cpId'] as String,
      role: data['role'] as String,
      isActive: data['isActive'] as bool? ?? true,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      leftAt: data['leftAt'] != null
          ? (data['leftAt'] as Timestamp).toDate()
          : null,
      pointsTotal: data['pointsTotal'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'cpId': cpId,
      'role': role,
      'isActive': isActive,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'pointsTotal': pointsTotal,
    };
  }

  /// Convert from domain entity to data model
  factory GroupMembershipModel.fromEntity(GroupMembershipEntity entity) {
    return GroupMembershipModel(
      id: entity.id,
      groupId: entity.groupId,
      cpId: entity.cpId,
      role: entity.role,
      isActive: entity.isActive,
      joinedAt: entity.joinedAt,
      leftAt: entity.leftAt,
      pointsTotal: entity.pointsTotal,
    );
  }

  /// Convert to domain entity
  GroupMembershipEntity toEntity() {
    return GroupMembershipEntity(
      id: id,
      groupId: groupId,
      cpId: cpId,
      role: role,
      isActive: isActive,
      joinedAt: joinedAt,
      leftAt: leftAt,
      pointsTotal: pointsTotal,
    );
  }
}
