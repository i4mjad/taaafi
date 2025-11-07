class GroupMembershipEntity {
  final String id;
  final String groupId;
  final String cpId;
  final String role; // 'admin' | 'member'
  final bool isActive;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int pointsTotal;
  
  // Activity tracking fields (Sprint 2 - Feature 2.1)
  final DateTime? lastActiveAt;
  final int messageCount;
  final int engagementScore;

  const GroupMembershipEntity({
    required this.id,
    required this.groupId,
    required this.cpId,
    required this.role,
    this.isActive = true,
    required this.joinedAt,
    this.leftAt,
    this.pointsTotal = 0,
    this.lastActiveAt,
    this.messageCount = 0,
    this.engagementScore = 0,
  });

  /// Check if member is inactive (no activity for more than X days)
  bool isInactive({int days = 7}) {
    if (lastActiveAt == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    return difference.inDays >= days;
  }

  /// Get engagement level based on score
  String get engagementLevel {
    if (engagementScore >= 50) return 'high';
    if (engagementScore >= 20) return 'medium';
    return 'low';
  }

  /// Get last active time description
  String? getLastActiveDescription() {
    if (lastActiveAt == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    
    if (difference.inMinutes < 5) return 'active-now';
    if (difference.inHours < 1) return 'active-minutes-ago';
    if (difference.inHours < 24) return 'active-hours-ago';
    if (difference.inDays < 7) return 'active-days-ago';
    return 'active-weeks-ago';
  }

  GroupMembershipEntity copyWith({
    String? id,
    String? groupId,
    String? cpId,
    String? role,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? leftAt,
    int? pointsTotal,
    DateTime? lastActiveAt,
    int? messageCount,
    int? engagementScore,
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
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      messageCount: messageCount ?? this.messageCount,
      engagementScore: engagementScore ?? this.engagementScore,
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
