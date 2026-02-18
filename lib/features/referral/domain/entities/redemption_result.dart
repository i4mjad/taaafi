class RedemptionResult {
  final bool success;
  final String? errorMessage;
  final String? referrerName;
  final String? referrerId;

  const RedemptionResult({
    required this.success,
    this.errorMessage,
    this.referrerName,
    this.referrerId,
  });

  factory RedemptionResult.success({
    required String referrerName,
    required String referrerId,
  }) {
    return RedemptionResult(
      success: true,
      referrerName: referrerName,
      referrerId: referrerId,
    );
  }

  factory RedemptionResult.error(String errorMessage) {
    return RedemptionResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  RedemptionResult copyWith({
    bool? success,
    String? errorMessage,
    String? referrerName,
    String? referrerId,
  }) {
    return RedemptionResult(
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      referrerName: referrerName ?? this.referrerName,
      referrerId: referrerId ?? this.referrerId,
    );
  }
}
