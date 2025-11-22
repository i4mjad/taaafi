import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../application/referral_providers.dart';

class VerificationCompleteWidget extends ConsumerWidget {
  const VerificationCompleteWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      backgroundColor: theme.success[50],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.success[200]!,
        width: 2,
      ),
      cornerSmoothing: 1,
      child: Column(
        children: [
          // Celebration emoji
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            l10n.translate('referral.checklist.celebration_title'),
            style: TextStyles.h4.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            l10n.translate('referral.checklist.celebration_message'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Reward info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.success[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.gift,
                  color: theme.success[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.translate('referral.checklist.premium_reward'),
                    style: TextStyles.body.copyWith(
                      color: theme.success[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _claimReward(context, ref, theme, l10n);
              },
              icon: const Icon(LucideIcons.gift),
              label: Text(
                l10n.translate('referral.checklist.claim_my_reward'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to Ta3afi Plus features
                context.pushNamed(RouteNames.ta3afiPlus.name);
              },
              icon: const Icon(LucideIcons.sparkles),
              label: Text(
                l10n.translate('referral.checklist.explore_premium'),
                style: TextStyles.footnoteSelected,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.success[700],
                side: BorderSide(color: theme.success[300]!, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Info text
          Text(
            l10n.translate('referral.checklist.referrer_notified'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _claimReward(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
  ) async {
    // Show loading bottom sheet
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spinner(),
            const SizedBox(height: 20),
            Text(
              l10n.translate('referral.checklist.claiming_reward'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    try {
      // Call repository to claim reward
      final container = ProviderScope.containerOf(context);
      final repository = container.read(referralRepositoryProvider);
      final result = await repository.claimRefereeReward();

      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      if (result.success) {
        // Show success dialog
        if (context.mounted) {
          _showSuccessDialog(
            context,
            theme,
            l10n,
            result.daysGranted!,
            result.expiresAt!,
          );
        }
      } else {
        // Show error message
        if (context.mounted) {
          _showErrorDialog(
            context,
            theme,
            l10n,
            result.errorMessage ?? l10n.translate('referral.checklist.claim_failed'),
          );
        }
      }
    } catch (e) {
      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        _showErrorDialog(
          context,
          theme,
          l10n,
          l10n.translate('referral.checklist.claim_failed'),
        );
      }
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    int daysGranted,
    DateTime expiresAt,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                l10n.translate('referral.checklist.reward_claimed'),
                style: TextStyles.h6.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n
                  .translate('referral.checklist.days_activated')
                  .replaceAll('{days}', daysGranted.toString()),
              style: TextStyles.body,
            ),
            const SizedBox(height: 12),
            Text(
              l10n
                  .translate('referral.dashboard.expires_at')
                  .replaceAll('{date}', _formatDate(expiresAt)),
              style: TextStyles.caption.copyWith(
                color: theme.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to premium features
              context.pushNamed(RouteNames.ta3afiPlus.name);
            },
            child: Text(l10n.translate('referral.checklist.explore_premium')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    String message,
  ) {
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
          message,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

