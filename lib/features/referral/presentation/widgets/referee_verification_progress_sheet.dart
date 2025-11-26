import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
import 'checklist_item_widget.dart';
import 'referee_rewards_list_widget.dart';
import 'referrer_info_card.dart';
import 'verification_progress_header.dart';

/// Bottom sheet showing referee's own verification progress
/// This is shown when a referee taps the banner in their referral dashboard
class RefereeVerificationProgressSheet extends ConsumerWidget {
  const RefereeVerificationProgressSheet({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RefereeVerificationProgressSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Container();
    }

    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('referral.checklist.my_progress_title'),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: verificationAsync.when(
              data: (verification) {
                if (verification == null) {
                  return _buildNotReferredState(context, theme, l10n);
                }

                final entity = verification.toEntity();

                if (entity.isBlocked) {
                  return _buildBlockedState(context, theme, l10n, entity.blockedReason);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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

                      // Checklist items (INTERACTIVE)
                      Text(
                        l10n.translate('referral.checklist.tasks_title'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ChecklistItemWidget(
                        type: ChecklistItemType.forumPosts3,
                        item: entity.forumPosts3,
                        isReadOnly: false,
                      ),
                      const SizedBox(height: 12),

                      ChecklistItemWidget(
                        type: ChecklistItemType.interactions5,
                        item: entity.interactions5,
                        isReadOnly: false,
                      ),
                      const SizedBox(height: 12),

                      ChecklistItemWidget(
                        type: ChecklistItemType.groupJoined,
                        item: entity.groupJoined,
                        isReadOnly: false,
                      ),
                      const SizedBox(height: 12),

                      ChecklistItemWidget(
                        type: ChecklistItemType.groupMessages3,
                        item: entity.groupMessages3,
                        isReadOnly: false,
                      ),
                      const SizedBox(height: 12),

                      ChecklistItemWidget(
                        type: ChecklistItemType.activityStarted,
                        item: entity.activityStarted,
                        isReadOnly: false,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: Spinner()),
              error: (_, __) => _buildErrorState(context, theme, l10n),
            ),
          ),
        ],
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

  Widget _buildBlockedState(
      BuildContext context, dynamic theme, AppLocalizations l10n, String? reason) {
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
          ],
        ),
      ),
    );
  }

  Future<String> _getReferrerName(WidgetRef ref, String referrerId) async {
    // TODO: Fetch from communityProfiles
    return 'Your Friend';
  }
}

