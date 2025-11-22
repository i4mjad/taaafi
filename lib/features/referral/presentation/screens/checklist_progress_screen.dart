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
import '../widgets/verification_complete_widget.dart';
import '../widgets/verification_progress_header.dart';

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

    // Get current logged-in user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Check if user is viewing their own progress or someone else's
    final isViewingOwnProgress = currentUserId == userId;

    // Watch the real-time stream of verification progress
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        isViewingOwnProgress 
            ? 'referral.checklist.title'
            : 'referral.checklist.user_progress',
        false,
        true,
      ),
      body: verificationAsync.when(
        data: (verification) {
          if (verification == null) {
            return _buildNoDataState(context, theme, l10n, isViewingOwnProgress);
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
                  // Banner showing who's progress this is (for referrers viewing referees)
                  if (!isViewingOwnProgress) ...[
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
                  ],
                  
                  // Referrer info card (if viewing own progress and not completed)
                  if (isViewingOwnProgress && !entity.isVerified) ...[
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

                  // Show rewards list ONLY if viewing own progress
                  if (isViewingOwnProgress) ...[
                    RefereeRewardsListWidget(userId: userId),
                    const SizedBox(height: 20),
                  ],

                  // Checklist items
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isViewingOwnProgress
                              ? l10n.translate('referral.checklist.tasks_title')
                              : l10n.translate('referral.checklist.their_tasks'),
                          style: TextStyles.h6.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isViewingOwnProgress)
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

                  // Account Age
                  ChecklistItemWidget(
                    type: ChecklistItemType.accountAge7Days,
                    item: entity.accountAge7Days,
                    signupDate: entity.signupDate,
                  ),
                  const SizedBox(height: 12),

                  // Forum Posts
                  ChecklistItemWidget(
                    type: ChecklistItemType.forumPosts3,
                    item: entity.forumPosts3,
                  ),
                  const SizedBox(height: 12),

                  // Interactions
                  ChecklistItemWidget(
                    type: ChecklistItemType.interactions5,
                    item: entity.interactions5,
                  ),
                  const SizedBox(height: 12),

                  // Group Joined
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupJoined,
                    item: entity.groupJoined,
                  ),
                  const SizedBox(height: 12),

                  // Group Messages
                  ChecklistItemWidget(
                    type: ChecklistItemType.groupMessages3,
                    item: entity.groupMessages3,
                  ),
                  const SizedBox(height: 12),

                  // Activity Started
                  ChecklistItemWidget(
                    type: ChecklistItemType.activityStarted,
                    item: entity.activityStarted,
                  ),
                  const SizedBox(height: 20),

                  // What happens next button (if not completed)
                  if (!entity.isVerified) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showWhatHappensNextSheet(context, theme, l10n);
                        },
                        icon: const Icon(LucideIcons.helpCircle),
                        label: Text(
                          l10n.translate('referral.checklist.what_happens_next'),
                          style: TextStyles.footnoteSelected,
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
                  ],

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
      BuildContext context, dynamic theme, AppLocalizations l10n, bool isViewingOwnProgress) {
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
              isViewingOwnProgress
                  ? l10n.translate('referral.checklist.no_data_title')
                  : l10n.translate('referral.checklist.no_referral_data'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isViewingOwnProgress
                  ? l10n.translate('referral.checklist.no_data_message')
                  : l10n.translate('referral.checklist.user_not_referred'),
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
    // TODO: Implement actual user name fetching
    return 'Your Friend';
  }

  void _showWhatHappensNextSheet(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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

              // Title
              Text(
                l10n.translate('referral.checklist.what_happens_title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Step 1
              _buildInfoStep(
                theme,
                l10n,
                '✅',
                l10n.translate('referral.checklist.step1_title'),
                l10n.translate('referral.checklist.step1_message'),
              ),
              const SizedBox(height: 16),

              // Step 2
              _buildInfoStep(
                theme,
                l10n,
                '🎁',
                l10n.translate('referral.checklist.step2_title'),
                l10n.translate('referral.checklist.step2_message'),
              ),
              const SizedBox(height: 16),

              // Step 3
              _buildInfoStep(
                theme,
                l10n,
                '📱',
                l10n.translate('referral.checklist.step3_title'),
                l10n.translate('referral.checklist.step3_message'),
              ),
              const SizedBox(height: 16),

              // Step 4
              _buildInfoStep(
                theme,
                l10n,
                '💰',
                l10n.translate('referral.checklist.step4_title'),
                l10n.translate('referral.checklist.step4_message'),
              ),
              const SizedBox(height: 24),

              // Close button
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
                    l10n.translate('common.got_it'),
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
      ),
    );
  }

  Widget _buildInfoStep(
    dynamic theme,
    AppLocalizations l10n,
    String emoji,
    String title,
    String message,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.body.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

