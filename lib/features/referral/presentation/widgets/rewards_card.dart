import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../data/models/referral_stats_model.dart';

class RewardsCard extends ConsumerWidget {
  final ReferralStatsModel stats;
  final VoidCallback? onRedeem;

  const RewardsCard({
    super.key,
    required this.stats,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final totalMonths = stats.rewardsEarned.totalMonths;
    final totalWeeks = stats.rewardsEarned.totalWeeks;
    final hasRewards = totalMonths > 0 || totalWeeks > 0;

    // Calculate progress to next milestone (every 5 verified users = 1 month)
    final currentVerified = stats.totalVerified;
    final nextMilestone = ((currentVerified ~/ 5) + 1) * 5;
    final usersToNextReward = nextMilestone - currentVerified;
    final progress = (currentVerified % 5) / 5.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.secondary[500]!,
            theme.secondary[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.secondary[500]!.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🎁',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.translate('referral.dashboard.rewards_title'),
                  style: TextStyles.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (hasRewards) ...[
            // Rewards earned
            _buildRewardItem(
              icon: '📅',
              label: l10n.translate('referral.dashboard.months_earned'),
              value: totalMonths.toString(),
            ),
            if (totalWeeks > 0) ...[
              const SizedBox(height: 12),
              _buildRewardItem(
                icon: '📆',
                label: l10n.translate('referral.dashboard.weeks_earned'),
                value: totalWeeks.toString(),
              ),
            ],
            const SizedBox(height: 20),
          ] else ...[
            // No rewards yet
            Text(
              l10n.translate('referral.dashboard.no_rewards_yet'),
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Progress to next milestone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('referral.dashboard.next_reward'),
                  style: TextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n
                      .translate('referral.dashboard.users_to_next_milestone')
                      .replaceAll('{count}', usersToNextReward.toString()),
                  style: TextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          if (hasRewards && onRedeem != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRedeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.secondary[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.translate('referral.dashboard.redeem_rewards'),
                  style: TextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyles.body.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyles.h5.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

