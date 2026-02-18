import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../application/referral_providers.dart';
import '../providers/referral_dashboard_provider.dart';

/// Bottom sheet for entering referral code after signup
class ReferralCodeInputSheet extends ConsumerStatefulWidget {
  const ReferralCodeInputSheet({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReferralCodeInputSheet(),
    );
  }

  @override
  ConsumerState<ReferralCodeInputSheet> createState() =>
      _ReferralCodeInputSheetState();
}

class _ReferralCodeInputSheetState
    extends ConsumerState<ReferralCodeInputSheet> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('referral.late_code.sheet_title'),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info text
                    Text(
                      l10n.translate('referral.late_code.description'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Code input
                    TextFormField(
                      controller: _codeController,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: l10n.translate('referral.input.enter_code'),
                        hintText: 'ABC123XY',
                        prefixIcon: Icon(
                          LucideIcons.ticket,
                          color: theme.primary[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('referral.input.code_required');
                        }
                        if (value.trim().length < 6) {
                          return l10n.translate('referral.input.code_too_short');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                l10n.translate('referral.late_code.submit'),
                                style: TextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final code = _codeController.text.trim().toUpperCase();

    try {
      final repository = ref.read(referralRepositoryProvider);
      final result = await repository.redeemReferralCode(code);

      if (!mounted) return;

      if (result.success) {
        // Close sheet
        Navigator.of(context).pop();

        // Show success
        _showSuccessDialog();

        // Refresh dashboard
        ref.invalidate(userVerificationProgressProvider);
        ref.invalidate(referralStatsProvider);
      } else {
        // Show error
        _showErrorDialog(result.errorMessage ?? 'referral.input.invalid');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('referral.input.invalid');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                l10n.translate('referral.late_code.success_title'),
                style: TextStyles.h6.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.translate('referral.late_code.success_message'),
          style: TextStyles.body,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorKey) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: theme.error[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('common.error'),
                style: TextStyles.h6.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.translate(errorKey),
          style: TextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.ok')),
          ),
        ],
      ),
    );
  }
}

