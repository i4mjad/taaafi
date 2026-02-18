class ReferralRewardsEarned {
  final int totalMonths;
  final int totalWeeks;
  final DateTime? lastRewardAt;

  const ReferralRewardsEarned({
    this.totalMonths = 0,
    this.totalWeeks = 0,
    this.lastRewardAt,
  });

  ReferralRewardsEarned copyWith({
    int? totalMonths,
    int? totalWeeks,
    DateTime? lastRewardAt,
  }) {
    return ReferralRewardsEarned(
      totalMonths: totalMonths ?? this.totalMonths,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      lastRewardAt: lastRewardAt ?? this.lastRewardAt,
    );
  }
}

class ReferralMilestone {
  final String type;
  final DateTime achievedAt;
  final String reward;

  const ReferralMilestone({
    required this.type,
    required this.achievedAt,
    required this.reward,
  });

  ReferralMilestone copyWith({
    String? type,
    DateTime? achievedAt,
    String? reward,
  }) {
    return ReferralMilestone(
      type: type ?? this.type,
      achievedAt: achievedAt ?? this.achievedAt,
      reward: reward ?? this.reward,
    );
  }
}

class ReferralStatsEntity {
  final String userId;
  final int totalReferred;
  final int totalVerified;
  final int totalPaidConversions;
  final int pendingVerifications;
  final int blockedReferrals;
  final ReferralRewardsEarned rewardsEarned;
  final List<ReferralMilestone> milestones;
  final DateTime lastUpdatedAt;

  const ReferralStatsEntity({
    required this.userId,
    this.totalReferred = 0,
    this.totalVerified = 0,
    this.totalPaidConversions = 0,
    this.pendingVerifications = 0,
    this.blockedReferrals = 0,
    required this.rewardsEarned,
    this.milestones = const [],
    required this.lastUpdatedAt,
  });

  ReferralStatsEntity copyWith({
    String? userId,
    int? totalReferred,
    int? totalVerified,
    int? totalPaidConversions,
    int? pendingVerifications,
    int? blockedReferrals,
    ReferralRewardsEarned? rewardsEarned,
    List<ReferralMilestone>? milestones,
    DateTime? lastUpdatedAt,
  }) {
    return ReferralStatsEntity(
      userId: userId ?? this.userId,
      totalReferred: totalReferred ?? this.totalReferred,
      totalVerified: totalVerified ?? this.totalVerified,
      totalPaidConversions: totalPaidConversions ?? this.totalPaidConversions,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      blockedReferrals: blockedReferrals ?? this.blockedReferrals,
      rewardsEarned: rewardsEarned ?? this.rewardsEarned,
      milestones: milestones ?? this.milestones,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferralStatsEntity && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
