import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/app_bar.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/shared_widgets/spinner.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
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
    final verificationAsync =
        ref.watch(userVerificationProgressProvider(userId));

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
            return _buildBlockedState(
                context, theme, l10n, entity.blockedReason);
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
                  // Progress header (always read-only for this screen)
                  VerificationProgressHeader(
                    completedItems: entity.completedItemsCount,
                    totalItems: entity.totalItemsCount,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 20),

                  // Tasks Container - Compact List View
                  WidgetsContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    backgroundColor: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.grey[200]!,
                      width: 1,
                    ),
                    cornerSmoothing: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.translate(
                                    'referral.checklist.their_tasks'),
                                style: TextStyles.body.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.translate('referral.checklist.read_only'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Compact task items
                        _buildCompactTaskItem(
                            theme,
                            l10n,
                            entity.forumPosts3.completed ? '✅' : '⏸️',
                            l10n.translate('referral.checklist.forum_posts'),
                            '${entity.forumPosts3.current ?? 0}/3 ${l10n.translate('referral.checklist.posts')}',
                            entity.forumPosts3.completed),

                        _buildCompactTaskItem(
                            theme,
                            l10n,
                            entity.interactions5.completed
                                ? '✅'
                                : entity.interactions5.current! > 0
                                    ? '⏳'
                                    : '⏸️',
                            l10n.translate('referral.checklist.interactions'),
                            '${entity.interactions5.current ?? 0}/5 ${l10n.translate('referral.checklist.interactions_count')}',
                            entity.interactions5.completed),

                        _buildCompactTaskItem(
                            theme,
                            l10n,
                            entity.groupJoined.completed ? '✅' : '⏸️',
                            l10n.translate('referral.checklist.join_group'),
                            entity.groupJoined.completed
                                ? l10n.translate('referral.checklist.completed')
                                : l10n
                                    .translate('referral.checklist.not_joined'),
                            entity.groupJoined.completed),

                        _buildCompactTaskItem(
                            theme,
                            l10n,
                            entity.groupMessages3.completed ? '✅' : '⏸️',
                            l10n.translate('referral.checklist.group_messages'),
                            '${entity.groupMessages3.current ?? 0}/3 ${l10n.translate('referral.checklist.messages')}',
                            entity.groupMessages3.completed),

                        _buildCompactTaskItem(
                            theme,
                            l10n,
                            entity.activityStarted.completed ? '✅' : '⏸️',
                            l10n.translate('referral.checklist.start_activity'),
                            entity.activityStarted.completed
                                ? l10n.translate('referral.checklist.completed')
                                : l10n.translate(
                                    'referral.checklist.no_activity'),
                            entity.activityStarted.completed,
                            isLast: true),
                      ],
                    ),
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

  Widget _buildCompactTaskItem(dynamic theme, AppLocalizations l10n,
      String emoji, String title, String status, bool isCompleted,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyles.small.copyWith(
                      color: isCompleted ? theme.success[700] : theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.grey[200]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
