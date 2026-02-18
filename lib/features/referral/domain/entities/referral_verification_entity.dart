class ChecklistItemEntity {
  final bool completed;
  final DateTime? completedAt;
  final int? current;
  final String? groupId;
  final String? activityId;
  final List<String>? uniqueUsers;

  const ChecklistItemEntity({
    required this.completed,
    this.completedAt,
    this.current,
    this.groupId,
    this.activityId,
    this.uniqueUsers,
  });

  ChecklistItemEntity copyWith({
    bool? completed,
    DateTime? completedAt,
    int? current,
    String? groupId,
    String? activityId,
    List<String>? uniqueUsers,
  }) {
    return ChecklistItemEntity(
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      current: current ?? this.current,
      groupId: groupId ?? this.groupId,
      activityId: activityId ?? this.activityId,
      uniqueUsers: uniqueUsers ?? this.uniqueUsers,
    );
  }
}

class ReferralVerificationEntity {
  final String userId;
  final String referrerId;
  final String referralCode;
  final DateTime signupDate;
  final String currentTier; // 'none' | 'verified' | 'paid'
  final ChecklistItemEntity accountAge7Days;
  final ChecklistItemEntity forumPosts3;
  final ChecklistItemEntity interactions5;
  final ChecklistItemEntity groupJoined;
  final ChecklistItemEntity groupMessages3;
  final ChecklistItemEntity activityStarted;
  final String verificationStatus; // 'pending' | 'verified' | 'blocked'
  final DateTime? verifiedAt;
  final int fraudScore;
  final List<String> fraudFlags;
  final bool isBlocked;
  final String? blockedReason;
  final DateTime? blockedAt;
  final bool rewardAwarded;
  final DateTime? rewardAwardedAt;
  final DateTime lastCheckedAt;
  final DateTime updatedAt;

  const ReferralVerificationEntity({
    required this.userId,
    required this.referrerId,
    required this.referralCode,
    required this.signupDate,
    required this.currentTier,
    required this.accountAge7Days,
    required this.forumPosts3,
    required this.interactions5,
    required this.groupJoined,
    required this.groupMessages3,
    required this.activityStarted,
    required this.verificationStatus,
    this.verifiedAt,
    this.fraudScore = 0,
    this.fraudFlags = const [],
    this.isBlocked = false,
    this.blockedReason,
    this.blockedAt,
    this.rewardAwarded = false,
    this.rewardAwardedAt,
    required this.lastCheckedAt,
    required this.updatedAt,
  });

  /// Get total checklist items completed
  /// Note: accountAge7Days requirement removed - users can verify immediately
  int get completedItemsCount {
    int count = 0;
    if (forumPosts3.completed) count++;
    if (interactions5.completed) count++;
    if (groupJoined.completed) count++;
    if (groupMessages3.completed) count++;
    if (activityStarted.completed) count++;
    return count;
  }

  /// Total checklist items (accountAge7Days removed)
  int get totalItemsCount => 5;

  /// Progress percentage (0-100)
  double get progressPercentage {
    return (completedItemsCount / totalItemsCount) * 100;
  }

  /// Check if verification is complete
  bool get isVerified => verificationStatus == 'verified';

  /// Check if verification is pending
  bool get isPending => verificationStatus == 'pending';

  /// Get display name for user (for privacy)
  String getDisplayName(int index) {
    return 'User ${index + 1}';
  }

  ReferralVerificationEntity copyWith({
    String? userId,
    String? referrerId,
    String? referralCode,
    DateTime? signupDate,
    String? currentTier,
    ChecklistItemEntity? accountAge7Days,
    ChecklistItemEntity? forumPosts3,
    ChecklistItemEntity? interactions5,
    ChecklistItemEntity? groupJoined,
    ChecklistItemEntity? groupMessages3,
    ChecklistItemEntity? activityStarted,
    String? verificationStatus,
    DateTime? verifiedAt,
    int? fraudScore,
    List<String>? fraudFlags,
    bool? isBlocked,
    String? blockedReason,
    DateTime? blockedAt,
    bool? rewardAwarded,
    DateTime? rewardAwardedAt,
    DateTime? lastCheckedAt,
    DateTime? updatedAt,
  }) {
    return ReferralVerificationEntity(
      userId: userId ?? this.userId,
      referrerId: referrerId ?? this.referrerId,
      referralCode: referralCode ?? this.referralCode,
      signupDate: signupDate ?? this.signupDate,
      currentTier: currentTier ?? this.currentTier,
      accountAge7Days: accountAge7Days ?? this.accountAge7Days,
      forumPosts3: forumPosts3 ?? this.forumPosts3,
      interactions5: interactions5 ?? this.interactions5,
      groupJoined: groupJoined ?? this.groupJoined,
      groupMessages3: groupMessages3 ?? this.groupMessages3,
      activityStarted: activityStarted ?? this.activityStarted,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      fraudScore: fraudScore ?? this.fraudScore,
      fraudFlags: fraudFlags ?? this.fraudFlags,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
      blockedAt: blockedAt ?? this.blockedAt,
      rewardAwarded: rewardAwarded ?? this.rewardAwarded,
      rewardAwardedAt: rewardAwardedAt ?? this.rewardAwardedAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

