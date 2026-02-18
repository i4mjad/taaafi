import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/referral_stats_entity.dart';

class ReferralStatsModel extends ReferralStatsEntity {
  const ReferralStatsModel({
    required super.userId,
    super.totalReferred,
    super.totalVerified,
    super.totalPaidConversions,
    super.pendingVerifications,
    super.blockedReferrals,
    required super.rewardsEarned,
    super.milestones,
    required super.lastUpdatedAt,
  });

  /// Create from Firestore document
  factory ReferralStatsModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Parse rewards earned
    final rewardsData = data['rewardsEarned'] as Map<String, dynamic>?;
    final rewardsEarned = ReferralRewardsEarned(
      totalMonths: rewardsData?['totalMonths'] as int? ?? 0,
      totalWeeks: rewardsData?['totalWeeks'] as int? ?? 0,
      lastRewardAt: rewardsData?['lastRewardAt'] != null
          ? (rewardsData!['lastRewardAt'] as Timestamp).toDate()
          : null,
    );

    // Parse milestones
    final milestonesData = data['milestones'] as List<dynamic>? ?? [];
    final milestones = milestonesData.map((m) {
      final milestone = m as Map<String, dynamic>;
      return ReferralMilestone(
        type: milestone['type'] as String,
        achievedAt: (milestone['achievedAt'] as Timestamp).toDate(),
        reward: milestone['reward'] as String,
      );
    }).toList();

    return ReferralStatsModel(
      userId: data['userId'] as String,
      totalReferred: data['totalReferred'] as int? ?? 0,
      totalVerified: data['totalVerified'] as int? ?? 0,
      totalPaidConversions: data['totalPaidConversions'] as int? ?? 0,
      pendingVerifications: data['pendingVerifications'] as int? ?? 0,
      blockedReferrals: data['blockedReferrals'] as int? ?? 0,
      rewardsEarned: rewardsEarned,
      milestones: milestones,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalReferred': totalReferred,
      'totalVerified': totalVerified,
      'totalPaidConversions': totalPaidConversions,
      'pendingVerifications': pendingVerifications,
      'blockedReferrals': blockedReferrals,
      'rewardsEarned': {
        'totalMonths': rewardsEarned.totalMonths,
        'totalWeeks': rewardsEarned.totalWeeks,
        'lastRewardAt': rewardsEarned.lastRewardAt != null
            ? Timestamp.fromDate(rewardsEarned.lastRewardAt!)
            : null,
      },
      'milestones': milestones
          .map((m) => {
                'type': m.type,
                'achievedAt': Timestamp.fromDate(m.achievedAt),
                'reward': m.reward,
              })
          .toList(),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  /// Convert from domain entity to data model
  factory ReferralStatsModel.fromEntity(ReferralStatsEntity entity) {
    return ReferralStatsModel(
      userId: entity.userId,
      totalReferred: entity.totalReferred,
      totalVerified: entity.totalVerified,
      totalPaidConversions: entity.totalPaidConversions,
      pendingVerifications: entity.pendingVerifications,
      blockedReferrals: entity.blockedReferrals,
      rewardsEarned: entity.rewardsEarned,
      milestones: entity.milestones,
      lastUpdatedAt: entity.lastUpdatedAt,
    );
  }

  /// Convert to domain entity
  ReferralStatsEntity toEntity() {
    return ReferralStatsEntity(
      userId: userId,
      totalReferred: totalReferred,
      totalVerified: totalVerified,
      totalPaidConversions: totalPaidConversions,
      pendingVerifications: pendingVerifications,
      blockedReferrals: blockedReferrals,
      rewardsEarned: rewardsEarned,
      milestones: milestones,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}
