import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/referral_code_entity.dart';

class ReferralCodeModel extends ReferralCodeEntity {
  const ReferralCodeModel({
    required super.id,
    required super.userId,
    required super.code,
    required super.createdAt,
    super.isActive,
    super.totalRedemptions,
    super.lastUsedAt,
  });

  /// Create from Firestore document
  factory ReferralCodeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReferralCodeModel(
      id: doc.id,
      userId: data['userId'] as String,
      code: data['code'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      totalRedemptions: data['totalRedemptions'] as int? ?? 0,
      lastUsedAt: data['lastUsedAt'] != null
          ? (data['lastUsedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'code': code,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'totalRedemptions': totalRedemptions,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    };
  }

  /// Convert from domain entity to data model
  factory ReferralCodeModel.fromEntity(ReferralCodeEntity entity) {
    return ReferralCodeModel(
      id: entity.id,
      userId: entity.userId,
      code: entity.code,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
      totalRedemptions: entity.totalRedemptions,
      lastUsedAt: entity.lastUsedAt,
    );
  }

  /// Convert to domain entity
  ReferralCodeEntity toEntity() {
    return ReferralCodeEntity(
      id: id,
      userId: userId,
      code: code,
      createdAt: createdAt,
      isActive: isActive,
      totalRedemptions: totalRedemptions,
      lastUsedAt: lastUsedAt,
    );
  }
}
