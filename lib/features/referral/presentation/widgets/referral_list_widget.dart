import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/spacing.dart';
import '../../../../core/theming/text_styles.dart';
import '../../data/models/referral_verification_model.dart';

class ReferralListWidget extends ConsumerWidget {
  final List<ReferralVerificationModel> referrals;
  final Function(ReferralVerificationModel)? onTap;

  const ReferralListWidget({
    super.key,
    required this.referrals,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    if (referrals.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.grey[200]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              '📢',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('referral.dashboard.no_referrals_title'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('referral.dashboard.no_referrals_message'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.translate('referral.dashboard.your_referrals'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: referrals.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return _ReferralListItem(
                referral: referral,
                index: index,
                onTap: onTap != null ? () => onTap!(referral) : null,
                theme: theme,
                l10n: l10n,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReferralListItem extends StatelessWidget {
  final ReferralVerificationModel referral;
  final int index;
  final VoidCallback? onTap;
  final dynamic theme;
  final AppLocalizations l10n;

  const _ReferralListItem({
    required this.referral,
    required this.index,
    this.onTap,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusInfo.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referral.getDisplayName(index),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        statusInfo.label,
                        style: TextStyles.caption.copyWith(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (referral.isPending) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${referral.completedItemsCount}/${referral.totalItemsCount})',
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow icon if tappable
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    if (referral.isBlocked) {
      return _StatusInfo(
        icon: '🚫',
        label: l10n.translate('referral.dashboard.status_blocked'),
        color: theme.error[600]!,
      );
    }

    if (referral.isVerified) {
      if (referral.currentTier == 'paid') {
        return _StatusInfo(
          icon: '💰',
          label: l10n.translate('referral.dashboard.status_premium'),
          color: theme.primary[600]!,
        );
      }
      return _StatusInfo(
        icon: '✅',
        label: l10n.translate('referral.dashboard.status_verified'),
        color: theme.success[600]!,
      );
    }

    return _StatusInfo(
      icon: '⏳',
      label: l10n.translate('referral.dashboard.status_pending'),
      color: theme.warning[600]!,
    );
  }
}

class _StatusInfo {
  final String icon;
  final String label;
  final Color color;

  _StatusInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}

