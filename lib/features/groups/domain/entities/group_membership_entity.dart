class GroupMembershipEntity {
  final String id;
  final String groupId;
  final String cpId;
  final String role; // 'admin' | 'member'
  final bool isActive;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int pointsTotal;

  const GroupMembershipEntity({
    required this.id,
    required this.groupId,
    required this.cpId,
    required this.role,
    this.isActive = true,
    required this.joinedAt,
    this.leftAt,
    this.pointsTotal = 0,
  });

  GroupMembershipEntity copyWith({
    String? id,
    String? groupId,
    String? cpId,
    String? role,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? leftAt,
    int? pointsTotal,
  }) {
    return GroupMembershipEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cpId: cpId ?? this.cpId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      pointsTotal: pointsTotal ?? this.pointsTotal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMembershipEntity && 
           other.groupId == groupId && 
           other.cpId == cpId;
  }

  @override
  int get hashCode => Object.hash(groupId, cpId);
}
