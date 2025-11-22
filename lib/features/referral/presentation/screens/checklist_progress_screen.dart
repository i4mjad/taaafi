import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
import '../widgets/checklist_item_widget.dart';
import '../widgets/verification_progress_header.dart';

/// Checklist Progress Screen
/// THIS SCREEN IS ONLY FOR REFERRERS TO VIEW THEIR REFERRED USERS' PROGRESS
/// IT IS ALWAYS READ-ONLY AND NEVER SHOWN TO THE REFEREE THEMSELVES
class ChecklistProgressScreen extends ConsumerWidget {
  final String userId;

  const ChecklistProgressScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    // Watch the real-time stream of verification progress
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'referral.checklist.user_progress',
        false,
        true,
      ),
      body: verificationAsync.when(
        data: (verification) {
          if (verification == null) {
            return _buildNoDataState(context, theme, l10n);
          }

          final entity = verification.toEntity();

          // Check if user is blocked
          if (entity.isBlocked) {
            return _buildBlockedState(context, theme, l10n, entity.blockedReason);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userVerificationProgressProvider(userId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner showing this is read-only view
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.primary[200]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.eye,
                          color: theme.primary[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.translate('referral.checklist.viewing_progress'),
                            style: TextStyles.body.copyWith(
                              color: theme.primary[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress header
                  VerificationProgressHeader(
                    completedItems: entity.completedItemsCount,
                    totalItems: entity.totalItemsCount,
                  ),
                  const SizedBox(height: 20),

                  // Checklist items header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.translate('referral.checklist.their_tasks'),
                          style: TextStyles.h6.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 14,
                              color: theme.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.translate('referral.checklist.read_only'),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Account Age (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.accountAge7Days,
                    item: entity.accountAge7Days,
                    signupDate: entity.signupDate,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Forum Posts (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.forumPosts3,
                    item: entity.forumPosts3,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Interactions (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.interactions5,
                    item: entity.interactions5,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Group Joined (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupJoined,
                    item: entity.groupJoined,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Group Messages (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupMessages3,
                    item: entity.groupMessages3,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Activity Started (ALWAYS READ-ONLY)
                  ChecklistItemWidget(
                    type: ChecklistItemType.activityStarted,
                    item: entity.activityStarted,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 20),

                  // NO OTHER BUTTONS - THIS IS PURELY FOR MONITORING
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spinner(),
              const SizedBox(height: 16),
              Text(
                l10n.translate('common.loading'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(context, theme, l10n),
      ),
    );
  }

  Widget _buildNoDataState(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('referral.checklist.no_referral_data'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('referral.checklist.user_not_referred'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedState(BuildContext context, dynamic theme,
      AppLocalizations l10n, String? reason) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shieldAlert,
              size: 64,
              color: theme.error[600],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('referral.checklist.under_review'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason ??
                  l10n.translate('referral.checklist.under_review_message'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: theme.error[600],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('common.error'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('referral.dashboard.error_loading'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

