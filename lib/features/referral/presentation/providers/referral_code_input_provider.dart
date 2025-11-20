import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import '../../application/referral_providers.dart';
import '../../domain/entities/redemption_result.dart';

part 'referral_code_input_provider.g.dart';

class ReferralCodeInputState {
  final String code;
  final bool isLoading;
  final String? error;
  final RedemptionResult? result;

  const ReferralCodeInputState({
    this.code = '',
    this.isLoading = false,
    this.error,
    this.result,
  });

  ReferralCodeInputState copyWith({
    String? code,
    bool? isLoading,
    String? error,
    RedemptionResult? result,
  }) {
    return ReferralCodeInputState(
      code: code ?? this.code,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Allow clearing error by passing null
      result: result ?? this.result,
    );
  }
}

@riverpod
class ReferralCodeInput extends _$ReferralCodeInput {
  @override
  ReferralCodeInputState build() {
    return const ReferralCodeInputState();
  }

  void setCode(String value) {
    // Auto-convert to uppercase and remove spaces
    final cleanCode = value.trim().toUpperCase();
    state = state.copyWith(code: cleanCode, error: null);
  }

  Future<void> submitCode() async {
    final code = state.code;

    if (code.length < 6 || code.length > 8) {
      state = state.copyWith(error: 'Code must be 6-8 characters long');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(referralRepositoryProvider);
      final result = await repository.redeemReferralCode(code);

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          result: result,
          error: null,
        );

        // Track successful verification
        ref
            .read(analyticsFacadeProvider)
            .trackScreenView('referral_code', 'verified_success');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Invalid referral code',
        );

        // Track submission failure
        final errorType = _getErrorType(result.errorMessage);
        ref
            .read(analyticsFacadeProvider)
            .trackScreenView('referral_code', 'verified_failed_$errorType');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );

      // Track network/unexpected error
      ref
          .read(analyticsFacadeProvider)
          .trackScreenView('referral_code', 'verified_failed_network');
    }
  }

  String _getErrorType(String? errorMessage) {
    if (errorMessage == null) return 'unknown';
    if (errorMessage.contains('Invalid')) return 'invalid';
    if (errorMessage.contains('already used')) return 'already_used';
    if (errorMessage.contains('own code')) return 'own_code';
    if (errorMessage.contains('no longer valid')) return 'expired';
    return 'unknown';
  }

  void reset() {
    state = const ReferralCodeInputState();
  }
}
