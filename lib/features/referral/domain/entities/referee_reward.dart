/// Represents a reward available to a referee (referred user)
class RefereeReward {
  final String id;
  final String type;
  final String title;
  final String description;
  final int daysGranted;
  final bool isClaimed;
  final DateTime? claimedAt;
  final DateTime? expiresAt;
  final bool isEligible;
  final String? ineligibilityReason;

  const RefereeReward({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.daysGranted,
    required this.isClaimed,
    this.claimedAt,
    this.expiresAt,
    required this.isEligible,
    this.ineligibilityReason,
  });

  factory RefereeReward.verificationReward({
    required bool isVerified,
    required bool isClaimed,
    DateTime? claimedAt,
    DateTime? expiresAt,
  }) {
    return RefereeReward(
      id: 'verification_reward',
      type: 'verification',
      title: '1 Month Premium',
      description: 'Complete all verification tasks to unlock',
      daysGranted: 30,
      isClaimed: isClaimed,
      claimedAt: claimedAt,
      expiresAt: expiresAt,
      isEligible: isVerified && !isClaimed,
      ineligibilityReason: !isVerified
          ? 'Complete all verification tasks first'
          : isClaimed
              ? 'Already claimed'
              : null,
    );
  }

  bool get isActive {
    if (!isClaimed || expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  bool get isExpired {
    if (!isClaimed || expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

