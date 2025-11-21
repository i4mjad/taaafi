import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
import '../widgets/how_it_works_sheet.dart';
import '../widgets/referral_code_card.dart';
import '../widgets/referral_list_widget.dart';
import '../widgets/referral_stats_card.dart';
import '../widgets/rewards_card.dart';

class ReferralDashboardScreen extends ConsumerWidget {
  const ReferralDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final referralCodeAsync = ref.watch(userReferralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);
    final referredUsersAsync = ref.watch(referredUsersProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'referral.dashboard.title',
        false,
        true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userReferralCodeProvider);
          ref.invalidate(referralStatsProvider);
          ref.invalidate(referredUsersProvider);
          
          // Wait for all providers to reload
          await Future.wait([
            ref.read(userReferralCodeProvider.future),
            ref.read(referralStatsProvider.future),
            ref.read(referredUsersProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral Code Card
              referralCodeAsync.when(
                data: (referralCode) {
                  if (referralCode == null) {
                    return _buildNoCodeCard(theme, l10n);
                  }
                  return ReferralCodeCard(
                    code: referralCode.code,
                    onShare: () {
                      // Log analytics or perform additional actions
                    },
                  );
                },
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => _buildErrorCard(theme, l10n),
              ),

              const SizedBox(height: 16),

              // Stats Card
              statsAsync.when(
                data: (stats) {
                  if (stats == null) {
                    return _buildNoStatsCard(theme, l10n);
                  }
                  return ReferralStatsCard(stats: stats);
                },
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => _buildErrorCard(theme, l10n),
              ),

              const SizedBox(height: 16),

              // Rewards Card
              statsAsync.when(
                data: (stats) {
                  if (stats == null) {
                    return const SizedBox.shrink();
                  }
                  return RewardsCard(
                    stats: stats,
                    onRedeem: () {
                      _showRedeemDialog(context, theme, l10n);
                    },
                  );
                },
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Referred Users List
              referredUsersAsync.when(
                data: (referredUsers) {
                  return ReferralListWidget(
                    referrals: referredUsers,
                    onTap: (referral) {
                      // Navigate to detailed progress (Sprint 08)
                      // For now, just show coming soon
                      _showComingSoonDialog(context, theme, l10n);
                    },
                  );
                },
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => _buildErrorCard(theme, l10n),
              ),

              const SizedBox(height: 16),

              // How It Works Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HowItWorksSheet.show(context);
                  },
                  icon: const Icon(LucideIcons.helpCircle),
                  label: Text(
                    l10n.translate('referral.dashboard.how_it_works'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary[600],
                    side: BorderSide(
                      color: theme.primary[300]!,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(dynamic theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.grey[200]!,
          width: 1,
        ),
      ),
      child: const Center(
        child: Spinner(),
      ),
    );
  }

  Widget _buildErrorCard(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.error[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.error[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: theme.error[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('referral.dashboard.error_loading'),
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCodeCard(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.warn[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.warn[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '⚠️',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('referral.dashboard.no_code_title'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('referral.dashboard.no_code_message'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoStatsCard(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.grey[200]!,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          l10n.translate('referral.dashboard.no_stats'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.translate('referral.dashboard.redeem_title'),
          style: TextStyles.h6.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.translate('referral.dashboard.redeem_message'),
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

  void _showComingSoonDialog(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.translate('referral.dashboard.progress_title'),
          style: TextStyles.h6.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.translate('referral.dashboard.progress_coming_soon'),
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

