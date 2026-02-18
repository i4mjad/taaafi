import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../application/referral_providers.dart';
import '../../domain/entities/referee_reward.dart';
import '../providers/referral_dashboard_provider.dart';

class RefereeRewardsListWidget extends ConsumerWidget {
  final String userId;

  const RefereeRewardsListWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    // Watch verification status to get rewards
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return verificationAsync.when(
      data: (verification) {
        if (verification == null) {
          return const SizedBox.shrink();
        }

        // Build rewards list
        final rewards = _buildRewardsList(verification);

        if (rewards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('referral.rewards.my_rewards_title'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...rewards.map((reward) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRewardCard(context, ref, theme, l10n, reward),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<RefereeReward> _buildRewardsList(dynamic verification) {
    final entity = verification.toEntity();
    final rewards = <RefereeReward>[];

    // Verification reward
    rewards.add(RefereeReward.verificationReward(
      isVerified: entity.isVerified,
      isClaimed: entity.rewardAwarded,
      claimedAt: entity.rewardAwardedAt,
      expiresAt: entity.rewardAwardedAt != null
          ? entity.rewardAwardedAt!.add(const Duration(days: 3))
          : null,
    ));

    return rewards;
  }

  Widget _buildRewardCard(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
    RefereeReward reward,
  ) {
    // Determine card color based on status
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData statusIcon;

    if (reward.isClaimed && reward.isActive) {
      // Active reward
      backgroundColor = theme.success[50]!;
      borderColor = theme.success[200]!;
      iconColor = theme.success[600]!;
      statusIcon = LucideIcons.checkCircle;
    } else if (reward.isClaimed && reward.isExpired) {
      // Expired reward
      backgroundColor = theme.grey[50]!;
      borderColor = theme.grey[200]!;
      iconColor = theme.grey[400]!;
      statusIcon = LucideIcons.clock;
    } else if (reward.isEligible) {
      // Ready to claim
      backgroundColor = theme.primary[50]!;
      borderColor = theme.primary[200]!;
      iconColor = theme.primary[600]!;
      statusIcon = LucideIcons.gift;
    } else {
      // Not eligible yet
      backgroundColor = theme.grey[50]!;
      borderColor = theme.grey[200]!;
      iconColor = theme.grey[400]!;
      statusIcon = LucideIcons.lock;
    }

    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 2),
      cornerSmoothing: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(l10n, reward),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (reward.isEligible && !reward.isClaimed)
                ElevatedButton(
                  onPressed: () => _claimReward(context, ref, theme, l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.translate('referral.rewards.claim_now'),
                    style: TextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (reward.isClaimed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reward.isActive
                    ? theme.success[100]
                    : theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    reward.isActive ? LucideIcons.checkCircle2 : LucideIcons.clock,
                    color: reward.isActive ? theme.success[700] : theme.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reward.isActive
                          ? l10n.translate('referral.rewards.active_until')
                                  .replaceAll('{date}', _formatDate(reward.expiresAt!))
                          : l10n.translate('referral.rewards.expired_on')
                                  .replaceAll('{date}', _formatDate(reward.expiresAt!)),
                      style: TextStyles.caption.copyWith(
                        color: reward.isActive ? theme.success[800] : theme.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n, RefereeReward reward) {
    if (reward.isClaimed && reward.isActive) {
      return l10n.translate('referral.rewards.status_active');
    } else if (reward.isClaimed && reward.isExpired) {
      return l10n.translate('referral.rewards.status_expired');
    } else if (reward.isEligible) {
      return l10n.translate('referral.rewards.status_ready_to_claim');
    } else {
      return reward.ineligibilityReason ?? l10n.translate('referral.rewards.status_locked');
    }
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
        // Refresh verification data
        ref.invalidate(userVerificationProgressProvider(userId));

        // Show success
        if (context.mounted) {
          _showSuccessSnackBar(context, theme, l10n, result.daysGranted!);
        }
      } else {
        // Show error
        if (context.mounted) {
          _showErrorSnackBar(
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
        _showErrorSnackBar(
          context,
          theme,
          l10n,
          l10n.translate('referral.checklist.claim_failed'),
        );
      }
    }
  }

  void _showSuccessSnackBar(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    int daysGranted,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('referral.rewards.claim_success')
                    .replaceAll('{days}', daysGranted.toString()),
                style: TextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: theme.success[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: theme.error[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

