/// Response from reward redemption operation
class RedemptionResponse {
  final bool success;
  final int? daysGranted;
  final DateTime? expiresAt;
  final Map<String, dynamic>? breakdown;
  final String? errorMessage;

  const RedemptionResponse({
    required this.success,
    this.daysGranted,
    this.expiresAt,
    this.breakdown,
    this.errorMessage,
  });

  factory RedemptionResponse.success({
    required int daysGranted,
    required DateTime expiresAt,
    Map<String, dynamic>? breakdown,
  }) {
    return RedemptionResponse(
      success: true,
      daysGranted: daysGranted,
      expiresAt: expiresAt,
      breakdown: breakdown,
    );
  }

  factory RedemptionResponse.error(String message) {
    return RedemptionResponse(
      success: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'RedemptionResponse(success: true, daysGranted: $daysGranted, expiresAt: $expiresAt)';
    } else {
      return 'RedemptionResponse(success: false, error: $errorMessage)';
    }
  }
}

