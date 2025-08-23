class GroupEntity {
  final String id;
  final String name;
  final String description;
  final String gender; // 'male' | 'female'
  final int memberCapacity;
  final String adminCpId;
  final String createdByCpId;
  final String visibility; // 'public' | 'private'
  final String joinMethod; // 'any' | 'admin_only' | 'code_only'
  final String? joinCodeHash;
  final DateTime? joinCodeExpiresAt;
  final int? joinCodeMaxUses;
  final int joinCodeUseCount;
  final bool isActive;
  final bool isPaused;
  final String? pauseReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.gender,
    required this.memberCapacity,
    required this.adminCpId,
    required this.createdByCpId,
    required this.visibility,
    required this.joinMethod,
    this.joinCodeHash,
    this.joinCodeExpiresAt,
    this.joinCodeMaxUses,
    this.joinCodeUseCount = 0,
    this.isActive = true,
    this.isPaused = false,
    this.pauseReason,
    required this.createdAt,
    required this.updatedAt,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? gender,
    int? memberCapacity,
    String? adminCpId,
    String? createdByCpId,
    String? visibility,
    String? joinMethod,
    String? joinCodeHash,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
    int? joinCodeUseCount,
    bool? isActive,
    bool? isPaused,
    String? pauseReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gender: gender ?? this.gender,
      memberCapacity: memberCapacity ?? this.memberCapacity,
      adminCpId: adminCpId ?? this.adminCpId,
      createdByCpId: createdByCpId ?? this.createdByCpId,
      visibility: visibility ?? this.visibility,
      joinMethod: joinMethod ?? this.joinMethod,
      joinCodeHash: joinCodeHash ?? this.joinCodeHash,
      joinCodeExpiresAt: joinCodeExpiresAt ?? this.joinCodeExpiresAt,
      joinCodeMaxUses: joinCodeMaxUses ?? this.joinCodeMaxUses,
      joinCodeUseCount: joinCodeUseCount ?? this.joinCodeUseCount,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      pauseReason: pauseReason ?? this.pauseReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
