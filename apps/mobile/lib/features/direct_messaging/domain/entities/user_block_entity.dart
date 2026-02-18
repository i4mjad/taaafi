import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity representing a user block relationship
class UserBlockEntity {
  final String id; // Format: ${blockerCpId}_${blockedCpId}
  final String blockerUid;
  final String blockerCpId;
  final String blockedUid;
  final String blockedCpId;
  final DateTime createdAt;
  final String? reason;

  const UserBlockEntity({
    required this.id,
    required this.blockerUid,
    required this.blockerCpId,
    required this.blockedUid,
    required this.blockedCpId,
    required this.createdAt,
    this.reason,
  });

  /// Generate deterministic block ID
  static String generateBlockId(String blockerCpId, String blockedCpId) {
    return '${blockerCpId}_$blockedCpId';
  }

  UserBlockEntity copyWith({
    String? id,
    String? blockerUid,
    String? blockerCpId,
    String? blockedUid,
    String? blockedCpId,
    DateTime? createdAt,
    String? reason,
  }) {
    return UserBlockEntity(
      id: id ?? this.id,
      blockerUid: blockerUid ?? this.blockerUid,
      blockerCpId: blockerCpId ?? this.blockerCpId,
      blockedUid: blockedUid ?? this.blockedUid,
      blockedCpId: blockedCpId ?? this.blockedCpId,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
    );
  }
}


