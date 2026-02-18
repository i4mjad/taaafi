import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_block_entity.dart';

/// Firestore model for UserBlockEntity
class UserBlockModel extends UserBlockEntity {
  const UserBlockModel({
    required super.id,
    required super.blockerUid,
    required super.blockerCpId,
    required super.blockedUid,
    required super.blockedCpId,
    required super.createdAt,
    super.reason,
  });

  /// Create from Firestore document
  factory UserBlockModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserBlockModel(
      id: doc.id,
      blockerUid: data['blockerUid'] as String,
      blockerCpId: data['blockerCpId'] as String,
      blockedUid: data['blockedUid'] as String,
      blockedCpId: data['blockedCpId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reason: data['reason'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'blockerUid': blockerUid,
      'blockerCpId': blockerCpId,
      'blockedUid': blockedUid,
      'blockedCpId': blockedCpId,
      'createdAt': Timestamp.fromDate(createdAt),
      'reason': reason,
    };
  }

  /// Create from entity
  factory UserBlockModel.fromEntity(UserBlockEntity entity) {
    return UserBlockModel(
      id: entity.id,
      blockerUid: entity.blockerUid,
      blockerCpId: entity.blockerCpId,
      blockedUid: entity.blockedUid,
      blockedCpId: entity.blockedCpId,
      createdAt: entity.createdAt,
      reason: entity.reason,
    );
  }
}


