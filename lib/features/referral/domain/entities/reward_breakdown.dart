/// Breakdown of available rewards
class RewardBreakdown {
  final int verificationDays;
  final int paidConversionDays;
  final int totalAwarded;
  final int pendingRedemption;

  const RewardBreakdown({
    required this.verificationDays,
    required this.paidConversionDays,
    required this.totalAwarded,
    required this.pendingRedemption,
  });

  int get totalEarned => verificationDays + paidConversionDays;

  bool get hasRewardsToRedeem => pendingRedemption > 0;

  factory RewardBreakdown.fromJson(Map<String, dynamic> json) {
    return RewardBreakdown(
      verificationDays: json['verificationRewards'] as int? ?? 0,
      paidConversionDays: json['paidConversionRewards'] as int? ?? 0,
      totalAwarded: json['totalAwarded'] as int? ?? 0,
      pendingRedemption: json['pendingRedemption'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'RewardBreakdown(verification: $verificationDays days, paid: $paidConversionDays days, pending: $pendingRedemption days)';
  }
}

