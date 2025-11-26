import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
import '../widgets/checklist_item_widget.dart';
import '../widgets/referee_rewards_list_widget.dart';
import '../widgets/referrer_info_card.dart';
import '../widgets/verification_progress_header.dart';

/// My Verification Progress Screen
/// THIS SCREEN IS FOR REFEREES TO VIEW THEIR OWN PROGRESS
/// IT IS INTERACTIVE WITH BUTTONS AND REWARDS
class MyVerificationProgressScreen extends ConsumerWidget {
  const MyVerificationProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Text(l10n.translate('common.error')),
        ),
      );
    }

    // Watch the real-time stream of verification progress
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'referral.checklist.my_progress_title',
        false,
        true,
      ),
      body: verificationAsync.when(
        data: (verification) {
          if (verification == null) {
            return _buildNotReferredState(context, theme, l10n);
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
                  // Referrer info card (if not completed)
                  if (!entity.isVerified) ...[
                    FutureBuilder<String>(
                      future: _getReferrerName(ref, entity.referrerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ReferrerInfoCard(
                            referrerName: snapshot.data!,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Progress header
                  VerificationProgressHeader(
                    completedItems: entity.completedItemsCount,
                    totalItems: entity.totalItemsCount,
                  ),
                  const SizedBox(height: 20),

                  // MY Rewards section
                  RefereeRewardsListWidget(userId: userId),
                  const SizedBox(height: 20),

                  // Checklist items (INTERACTIVE - with buttons)
                  Text(
                    l10n.translate('referral.checklist.tasks_title'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Forum Posts (interactive)
                  ChecklistItemWidget(
                    type: ChecklistItemType.forumPosts3,
                    item: entity.forumPosts3,
                    isReadOnly: false,
                  ),
                  const SizedBox(height: 12),

                  // Interactions (interactive)
                  ChecklistItemWidget(
                    type: ChecklistItemType.interactions5,
                    item: entity.interactions5,
                    isReadOnly: false,
                  ),
                  const SizedBox(height: 12),

                  // Group Joined (interactive)
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupJoined,
                    item: entity.groupJoined,
                    isReadOnly: false,
                  ),
                  const SizedBox(height: 12),

                  // Group Messages (interactive)
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupMessages3,
                    item: entity.groupMessages3,
                    isReadOnly: false,
                  ),
                  const SizedBox(height: 12),

                  // Activity Started (interactive)
                  ChecklistItemWidget(
                    type: ChecklistItemType.activityStarted,
                    item: entity.activityStarted,
                    isReadOnly: false,
                  ),

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

  Widget _buildNotReferredState(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.info,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('referral.checklist.not_referred_title'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('referral.checklist.not_referred_message'),
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

  Future<String> _getReferrerName(WidgetRef ref, String referrerId) async {
    // Try to get referrer's name from Firestore
    // For now, return a placeholder
    // TODO: Implement actual user name fetching from communityProfiles
    return 'Your Friend';
  }
}

