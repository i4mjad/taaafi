import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/snackbar.dart';
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
      width: double.infinity,
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateReferralCode(context, theme, l10n),
              icon: const Icon(LucideIcons.plus),
              label: Text(
                l10n.translate('referral.dashboard.generate_code'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[500],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
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

  Future<void> _generateReferralCode(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const Spinner(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                l10n.translate('referral.dashboard.generating_code'),
                style: TextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Call Cloud Function to generate referral code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateUserReferralCode');
      
      final result = await callable.call();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (result.data['success'] == true) {
        // Show success message
        getSuccessSnackBar(context, 'referral.dashboard.code_generated');
        
        // Refresh the dashboard
        if (context.mounted) {
          final container = ProviderScope.containerOf(context);
          container.invalidate(userReferralCodeProvider);
          container.invalidate(referralStatsProvider);
        }
      } else {
        // Show error message
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                l10n.translate('common.error'),
                style: TextStyles.h6.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                result.data['message'] ?? 
                    l10n.translate('referral.dashboard.generation_failed'),
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
    } on FirebaseFunctionsException catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error dialog
      if (context.mounted) {
        String errorMessage;
        switch (e.code) {
          case 'already-exists':
            errorMessage = l10n.translate('referral.dashboard.code_already_exists');
            break;
          case 'resource-exhausted':
            errorMessage = l10n.translate('referral.dashboard.generation_limit_reached');
            break;
          default:
            errorMessage = l10n.translate('referral.dashboard.generation_failed');
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              l10n.translate('common.error'),
              style: TextStyles.h6.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              errorMessage,
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
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show generic error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              l10n.translate('common.error'),
              style: TextStyles.h6.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              l10n.translate('referral.dashboard.generation_failed'),
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
  }
}

