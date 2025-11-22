import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/shared_widgets/snackbar.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../application/referral_providers.dart';
import '../providers/referral_dashboard_provider.dart';
import '../widgets/how_it_works_sheet.dart';
import '../widgets/referral_code_card.dart';
import '../widgets/referral_list_widget.dart';
import '../widgets/referral_stats_card.dart';
import '../widgets/rewards_card.dart';
import '../widgets/referee_verification_progress_sheet.dart';

class ReferralDashboardScreen extends ConsumerWidget {
  const ReferralDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final referralCodeAsync = ref.watch(userReferralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);
    final referredUsersAsync = ref.watch(referredUsersProvider);
    
    // Check if current user is a referee
    final myVerificationAsync = userId != null 
        ? ref.watch(userVerificationProgressProvider(userId))
        : null;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'referral.dashboard.title',
        false,
        true,
        actions: [
          IconButton(
            onPressed: () {
              HowItWorksSheet.show(context);
            },
            icon: Icon(
              LucideIcons.helpCircle,
              color: theme.grey[900],
            ),
            tooltip: l10n.translate('referral.dashboard.how_it_works'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userReferralCodeProvider);
          ref.invalidate(referralStatsProvider);
          ref.invalidate(referredUsersProvider);
          if (userId != null) {
            ref.invalidate(userVerificationProgressProvider(userId));
          }

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
              // Referee Banner - Show if user was referred
              if (myVerificationAsync != null)
                myVerificationAsync.when(
                  data: (verification) {
                    if (verification != null) {
                      return Column(
                        children: [
                          _buildRefereeBanner(context, ref, theme, l10n, verification),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              // Referral Code Card
              referralCodeAsync.when(
                data: (referralCode) {
                  if (referralCode == null) {
                    return _buildNoCodeCard(context, theme, l10n);
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
                      // Navigate to detailed progress
                      context.pushNamed(
                        RouteNames.checklistProgress.name,
                        pathParameters: {'userId': referral.userId},
                      );
                    },
                  );
                },
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => _buildErrorCard(theme, l10n),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(dynamic theme) {
    return WidgetsContainer(
      height: 120,
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
      child: const Center(
        child: Spinner(),
      ),
    );
  }

  Widget _buildErrorCard(dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.error[50],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.error[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
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

  Widget _buildNoCodeCard(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.warn[50],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.warn[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
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
                style: TextStyles.footnoteSelected,
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
    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
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
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('referral.dashboard.confirm_redeem')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

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
              l10n.translate('referral.dashboard.redeeming_rewards'),
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
      // Call repository to redeem rewards
      final container = ProviderScope.containerOf(context);
      final repository = container.read(referralRepositoryProvider);
      final result = await repository.redeemReferralRewards();

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

          // Refresh the dashboard
          container.invalidate(referralStatsProvider);
          container.invalidate(referredUsersProvider);
        }
      } else {
        // Show error message
        if (context.mounted) {
          _showErrorSheet(
            context,
            theme,
            l10n,
            result.errorMessage ?? l10n.translate('referral.dashboard.redemption_failed'),
          );
        }
      }
    } catch (e) {
      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        _showErrorSheet(
          context,
          theme,
          l10n,
          l10n.translate('referral.dashboard.redemption_failed'),
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
                l10n.translate('referral.dashboard.redemption_success'),
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
                  .translate('referral.dashboard.days_granted')
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

  Future<void> _generateReferralCode(
    BuildContext context,
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
              l10n.translate('referral.dashboard.generating_code'),
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
      // Call Cloud Function to generate referral code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateUserReferralCode');

      final result = await callable.call();

      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      print('✅ Function call result: ${result.data}');

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
          _showErrorSheet(
            context,
            theme,
            l10n,
            result.data['message'] ??
                l10n.translate('referral.dashboard.generation_failed'),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      print('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      print('Details: ${e.details}');

      // Show error sheet
      if (context.mounted) {
        String errorMessage;
        switch (e.code) {
          case 'already-exists':
            errorMessage =
                l10n.translate('referral.dashboard.code_already_exists');
            break;
          case 'resource-exhausted':
            errorMessage =
                l10n.translate('referral.dashboard.generation_limit_reached');
            break;
          default:
            errorMessage =
                '${l10n.translate('referral.dashboard.generation_failed')}\n\nError: ${e.code}';
        }

        _showErrorSheet(context, theme, l10n, errorMessage);
      }
    } catch (e) {
      // Close loading sheet
      if (context.mounted) Navigator.of(context).pop();

      print('❌ General error: $e');

      // Show generic error
      if (context.mounted) {
        _showErrorSheet(
          context,
          theme,
          l10n,
          '${l10n.translate('referral.dashboard.generation_failed')}\n\nError: $e',
        );
      }
    }
  }

  void _showErrorSheet(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              LucideIcons.alertCircle,
              color: theme.error[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('common.error'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.translate('common.ok'),
                  style: TextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRefereeBanner(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
    dynamic verification,
  ) {
    final entity = verification.toEntity();

    // Determine banner style
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String title;
    String subtitle;
    IconData icon;

    if (entity.isVerified && !entity.rewardAwarded) {
      // Verified but reward not claimed
      backgroundColor = theme.success[50]!;
      borderColor = theme.success[300]!;
      textColor = theme.success[900]!;
      icon = LucideIcons.gift;
      title = l10n.translate('referral.banner.reward_ready');
      subtitle = l10n.translate('referral.banner.claim_3_days');
    } else if (entity.isVerified && entity.rewardAwarded) {
      // All done - don't show banner
      return const SizedBox.shrink();
    } else {
      // Still working on verification
      backgroundColor = theme.primary[50]!;
      borderColor = theme.primary[200]!;
      textColor = theme.primary[900]!;
      icon = LucideIcons.target;
      title = l10n
          .translate('referral.banner.progress_title')
          .replaceAll('{completed}', entity.completedItemsCount.toString())
          .replaceAll('{total}', entity.totalItemsCount.toString());
      subtitle = l10n.translate('referral.banner.complete_tasks');
    }

    return GestureDetector(
      onTap: () {
        // Show bottom sheet with progress
        RefereeVerificationProgressSheet.show(context, ref);
      },
      child: WidgetsContainer(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
          width: 2,
        ),
        cornerSmoothing: 1,
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: textColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
