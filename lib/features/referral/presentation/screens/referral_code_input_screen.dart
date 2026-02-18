import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/referral/presentation/widgets/referral_code_input_widget.dart';

/// Referral Code Input Screen
///
/// Optional step in signup flow where new users can enter a referral code
/// to link them to their referrer and unlock rewards.
class ReferralCodeInputScreen extends ConsumerStatefulWidget {
  const ReferralCodeInputScreen({
    super.key,
    this.onComplete,
  });

  /// Callback when user completes (either verified or skipped)
  final VoidCallback? onComplete;

  @override
  ConsumerState<ReferralCodeInputScreen> createState() =>
      _ReferralCodeInputScreenState();
}

class _ReferralCodeInputScreenState
    extends ConsumerState<ReferralCodeInputScreen> {
  @override
  void initState() {
    super.initState();
    // Track that screen was shown
    Future.microtask(() {
      ref
          .read(analyticsFacadeProvider)
          .trackScreenView('referral_code_input', 'shown');
    });
  }

  void _handleSuccess() {
    // Analytics tracked in the provider
    // Navigate to next step
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Default: go back or to home
      context.pop();
    }
  }

  void _handleSkip() {
    // Track skip event
    ref
        .read(analyticsFacadeProvider)
        .trackScreenView('referral_code_input', 'skipped');

    // Navigate to next step
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Default: go back or to home
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'referral.input.title',
        true,
        true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Illustration
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.primary[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 40,
                    color: theme.primary[600],
                  ),
                ),
              ),

              verticalSpace(Spacing.points24),

              // Title
              Text(
                AppLocalizations.of(context).translate('referral.input.title'),
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points12),

              // Subtitle
              Text(
                AppLocalizations.of(context).translate('referral.input.subtitle'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points32),

              // Referral code input widget
              ReferralCodeInputWidget(
                onSuccess: _handleSuccess,
                onSkip: _handleSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

