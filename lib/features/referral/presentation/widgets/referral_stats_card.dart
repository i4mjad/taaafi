import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../data/models/referral_stats_model.dart';

class ReferralStatsCard extends ConsumerWidget {
  final ReferralStatsModel stats;

  const ReferralStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('referral.dashboard.stats_title'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: '👥',
                      label:
                          l10n.translate('referral.dashboard.total_referrals'),
                      value: stats.totalReferred.toString(),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatItem(
                      icon: '✅',
                      label: l10n.translate('referral.dashboard.verified'),
                      value: stats.totalVerified.toString(),
                      theme: theme,
                      valueColor: theme.success[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: '💰',
                      label:
                          l10n.translate('referral.dashboard.paid_conversions'),
                      value: stats.totalPaidConversions.toString(),
                      theme: theme,
                      valueColor: theme.primary[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatItem(
                      icon: '⏳',
                      label: l10n.translate('referral.dashboard.pending'),
                      value: stats.pendingVerifications.toString(),
                      theme: theme,
                      valueColor: theme.warn[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final dynamic theme;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: theme.grey[50],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.grey[100]!,
        width: 1,
      ),
      cornerSmoothing: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.h4.copyWith(
              color: valueColor ?? theme.grey[900],
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
