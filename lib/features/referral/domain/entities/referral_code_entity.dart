class ReferralCodeEntity {
  final String id;
  final String userId;
  final String code;
  final DateTime createdAt;
  final bool isActive;
  final int totalRedemptions;
  final DateTime? lastUsedAt;

  const ReferralCodeEntity({
    required this.id,
    required this.userId,
    required this.code,
    required this.createdAt,
    this.isActive = true,
    this.totalRedemptions = 0,
    this.lastUsedAt,
  });

  ReferralCodeEntity copyWith({
    String? id,
    String? userId,
    String? code,
    DateTime? createdAt,
    bool? isActive,
    int? totalRedemptions,
    DateTime? lastUsedAt,
  }) {
    return ReferralCodeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      totalRedemptions: totalRedemptions ?? this.totalRedemptions,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferralCodeEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
