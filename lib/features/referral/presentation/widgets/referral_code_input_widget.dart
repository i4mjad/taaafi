import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/referral/presentation/providers/referral_code_input_provider.dart';

/// Reusable referral code input widget
///
/// Can be used in signup flow or settings.
/// Provides text field with formatting, validation, loading state, and error display.
class ReferralCodeInputWidget extends ConsumerStatefulWidget {
  const ReferralCodeInputWidget({
    super.key,
    required this.onSuccess,
    this.onSkip,
  });

  /// Called when code is successfully verified
  final VoidCallback onSuccess;

  /// Called when user skips (optional)
  final VoidCallback? onSkip;

  @override
  ConsumerState<ReferralCodeInputWidget> createState() =>
      _ReferralCodeInputWidgetState();
}

class _ReferralCodeInputWidgetState
    extends ConsumerState<ReferralCodeInputWidget> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final state = ref.watch(referralCodeInputProvider);

    // Listen for successful redemption
    ref.listen<ReferralCodeInputState>(
      referralCodeInputProvider,
      (previous, next) {
        if (next.result != null && next.result!.success) {
          widget.onSuccess();
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Code input field
        TextField(
          controller: _codeController,
          enabled: !state.isLoading,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          style: TextStyles.body.copyWith(
            color: theme.grey[900],
            letterSpacing: 2,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          onChanged: (value) {
            ref.read(referralCodeInputProvider.notifier).setCode(value);
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)
                .translate('referral.input.placeholder'),
            hintStyle: TextStyles.body.copyWith(color: theme.grey[400]),
            prefixIcon: Icon(
              LucideIcons.ticket,
              color: theme.primary[600],
              size: 20,
            ),
            filled: true,
            fillColor: theme.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary[600]!, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.grey[200]!, width: 1),
            ),
            counterText: '',
          ),
        ),

        // Error message
        if (state.error != null) ...[
          verticalSpace(Spacing.points12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.error[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.error[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: theme.error[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate(state.error!),
                    style: TextStyles.small.copyWith(
                      color: theme.error[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Success message
        if (state.result != null && state.result!.success) ...[
          verticalSpace(Spacing.points12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.success[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.success[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  color: theme.success[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('referral.input.success')
                        .replaceAll(
                            '{referrerName}', state.result!.referrerName ?? ''),
                    style: TextStyles.small.copyWith(
                      color: theme.success[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        verticalSpace(Spacing.points16),

        // Verify button
        ElevatedButton(
          onPressed: state.isLoading || state.code.isEmpty
              ? null
              : () {
                  ref.read(referralCodeInputProvider.notifier).submitCode();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isLoading || state.code.isEmpty
                ? theme.grey[400]
                : theme.primary[600],
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.5),
            ),
          ),
          child: state.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Spinner(
                        strokeWidth: 2,
                        valueColor: theme.grey[50],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('verifying'),
                      style: TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
                  ],
                )
              : Text(
                  AppLocalizations.of(context)
                      .translate('referral.input.verify'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[50]),
                ),
        ),

        // Skip button (if provided)
        if (widget.onSkip != null) ...[
          verticalSpace(Spacing.points12),
          TextButton(
            onPressed: state.isLoading ? null : widget.onSkip,
            child: Text(
              AppLocalizations.of(context).translate('referral.input.skip'),
              style: TextStyles.footnote.copyWith(
                color: state.isLoading ? theme.grey[400] : theme.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Text formatter that converts input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
