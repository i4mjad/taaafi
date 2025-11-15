import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/confirmation_sheet.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_detail_notifier.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String groupId;
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.groupId,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final detailAsync =
        ref.watch(challengeDetailNotifierProvider(challengeId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('challenge-details'),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: detailAsync.when(
        data: (state) {
          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: TextStyles.body.copyWith(color: theme.error[600]),
              ),
            );
          }

          if (state.challenge == null) {
            return Center(
              child: Text(l10n.translate('challenge-not-found')),
            );
          }

          final challenge = state.challenge!;
          final userParticipation = state.userParticipation;
          final isParticipating = userParticipation != null;

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(challengeDetailNotifierProvider(challengeId).notifier).refresh();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(context, theme, l10n, challenge),

                  verticalSpace(Spacing.points16),

                  // Description Card
                  _buildDescriptionCard(theme, l10n, challenge),

                  verticalSpace(Spacing.points16),

                  // Stats Card
                  _buildStatsCard(theme, l10n, challenge, state.stats),

                  verticalSpace(Spacing.points16),

                  // User Progress Card (if participating)
                  if (isParticipating) ...[
                    _buildUserProgressCard(
                        context, theme, l10n, challenge, userParticipation),
                    verticalSpace(Spacing.points16),
                  ],

                  // Leaderboard Preview
                  _buildLeaderboardPreview(
                      context, theme, l10n, state.leaderboard, userParticipation),

                  verticalSpace(Spacing.points16),

                  // Action Buttons
                  _buildActionButtons(context, ref, theme, l10n, challenge,
                      isParticipating, state.isLoading),

                  verticalSpace(Spacing.points24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            '${l10n.translate('error')}: ${error.toString()}',
            style: TextStyles.body.copyWith(color: theme.error[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, theme, AppLocalizations l10n, ChallengeEntity challenge) {
    Color headerColor;
    IconData headerIcon;

    switch (challenge.type) {
      case ChallengeType.duration:
        headerColor = theme.primary[600]!;
        headerIcon = LucideIcons.clock;
        break;
      case ChallengeType.goal:
        headerColor = theme.success[600]!;
        headerIcon = LucideIcons.target;
        break;
      case ChallengeType.team:
        headerColor = theme.secondary[600]!;
        headerIcon = LucideIcons.users;
        break;
      case ChallengeType.recurring:
        headerColor = theme.warn[600]!;
        headerIcon = LucideIcons.repeat;
        break;
    }

    return WidgetsContainer(
      backgroundColor: headerColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: headerColor.withValues(alpha: 0.3), width: 2),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(headerIcon, size: 16, color: headerColor),
                    const SizedBox(width: 6),
                    Text(
                      _getChallengeTypeLabel(l10n, challenge.type),
                      style: TextStyles.caption.copyWith(
                        color: headerColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              _buildStatusBadge(theme, l10n, challenge),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Title
          Text(
            challenge.title,
            style: TextStyles.h3.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),

          verticalSpace(Spacing.points12),

          // Info Row
          Row(
            children: [
              Icon(LucideIcons.users, size: 18, color: theme.grey[700]),
              const SizedBox(width: 6),
              Text(
                '${challenge.participantCount} ${l10n.translate('participants')}',
                style: TextStyles.small.copyWith(color: theme.grey[700]),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.calendar, size: 18, color: theme.grey[700]),
              const SizedBox(width: 6),
              Text(
                '${challenge.getDaysRemaining()} ${l10n.translate('days-left')}',
                style: TextStyles.small.copyWith(color: theme.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
      theme, AppLocalizations l10n, ChallengeEntity challenge) {
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('description'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          verticalSpace(Spacing.points8),
          Text(
            challenge.description,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(theme, AppLocalizations l10n, ChallengeEntity challenge, stats) {
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('challenge-stats'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  l10n,
                  LucideIcons.users,
                  '${challenge.participantCount}',
                  l10n.translate('participants'),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  l10n,
                  LucideIcons.calendar,
                  '${challenge.durationDays}',
                  l10n.translate('days'),
                ),
              ),
              if (stats != null)
                Expanded(
                  child: _buildStatItem(
                    theme,
                    l10n,
                    LucideIcons.trendingUp,
                    '${stats.averageProgress.toStringAsFixed(0)}%',
                    l10n.translate('avg-progress'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      theme, AppLocalizations l10n, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.primary[600]),
        verticalSpace(Spacing.points8),
        Text(
          value,
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserProgressCard(BuildContext context, theme, AppLocalizations l10n,
      ChallengeEntity challenge, userParticipation) {
    final progressPercent = userParticipation.getProgressPercentage();

    return WidgetsContainer(
      backgroundColor: theme.success[50],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.success[200]!, width: 1),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('your-progress'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progressPercent.toStringAsFixed(0)}%',
                style: TextStyles.h5.copyWith(
                  color: theme.success[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 12,
              backgroundColor: theme.grey[200],
              valueColor: AlwaysStoppedAnimation(theme.success[600]!),
            ),
          ),
          verticalSpace(Spacing.points12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${userParticipation.currentValue} / ${userParticipation.goalValue}',
                style: TextStyles.small.copyWith(color: theme.grey[700]),
              ),
              if (userParticipation.rank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.warn[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${l10n.translate('rank')}: #${userParticipation.rank}',
                    style: TextStyles.caption.copyWith(
                      color: theme.warn[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreview(
      BuildContext context, theme, AppLocalizations l10n, leaderboard, userParticipation) {
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('leaderboard'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (leaderboard.isNotEmpty)
                TextButton(
                  onPressed: () => _navigateToLeaderboard(context),
                  child: Text(
                    l10n.translate('view-all'),
                    style: TextStyles.small.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.translate('no-participants-yet'),
                  style: TextStyles.small.copyWith(color: theme.grey[600]),
                ),
              ),
            )
          else
            ...leaderboard.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              final isCurrentUser =
                  userParticipation != null && participant.cpId == userParticipation.cpId;

              return _buildLeaderboardItem(
                theme,
                l10n,
                index + 1,
                participant,
                isCurrentUser,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
      theme, AppLocalizations l10n, int rank, participant, bool isCurrentUser) {
    Color? backgroundColor;
    if (isCurrentUser) {
      backgroundColor = theme.primary[50];
    } else if (rank == 1) {
      backgroundColor = theme.warn[50];
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? theme.warn[100] : theme.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyles.smallBold.copyWith(
                  color: rank <= 3 ? theme.warn[700] : theme.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info (placeholder)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? l10n.translate('you') : l10n.translate('participant'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[900],
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Text(
            '${participant.progress}%',
            style: TextStyles.smallBold.copyWith(
              color: theme.success[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, theme,
      AppLocalizations l10n, ChallengeEntity challenge, bool isParticipating, bool isLoading) {
    if (isParticipating) {
      return Column(
        children: [
          // Update Progress Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _showUpdateProgressDialog(context, ref, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(LucideIcons.trendingUp, color: Colors.white),
              label: Text(
                l10n.translate('update-progress'),
                style: TextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),
          // Leave Challenge Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _confirmLeaveChallenge(context, ref, l10n),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.error[600]!, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(LucideIcons.logOut, color: theme.error[600]),
              label: Text(
                l10n.translate('leave-challenge'),
                style: TextStyles.small.copyWith(
                  color: theme.error[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Not participating - show Join button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            isLoading || !challenge.canJoin('') ? null : () => _joinChallenge(context, ref, l10n),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(LucideIcons.userPlus, color: Colors.white),
        label: Text(
          l10n.translate('join-challenge'),
          style: TextStyles.h6.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(theme, AppLocalizations l10n, ChallengeEntity challenge) {
    if (challenge.status == ChallengeStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.success[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              l10n.translate('completed'),
              style: TextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (challenge.isEndingSoon()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.error[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              l10n.translate('ending-soon'),
              style: TextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getChallengeTypeLabel(AppLocalizations l10n, ChallengeType type) {
    switch (type) {
      case ChallengeType.duration:
        return l10n.translate('duration-challenge');
      case ChallengeType.goal:
        return l10n.translate('goal-challenge');
      case ChallengeType.team:
        return l10n.translate('team-challenge');
      case ChallengeType.recurring:
        return l10n.translate('recurring-challenge');
    }
  }

  void _navigateToLeaderboard(BuildContext context) {
    context.pushNamed(
      RouteNames.challengeLeaderboard.name,
      pathParameters: {
        'groupId': groupId,
        'challengeId': challengeId,
      },
    );
  }

  Future<void> _joinChallenge(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    await ref.read(challengeDetailNotifierProvider(challengeId).notifier).joinChallenge();

    if (!context.mounted) return;

    getSuccessSnackBar(
      context,
      'challenge-joined',
    );
  }

  Future<void> _confirmLeaveChallenge(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showConfirmationSheet(
      context: context,
      title: l10n.translate('leave-challenge'),
      message: l10n.translate('confirm-leave-challenge'),
      confirmText: l10n.translate('leave'),
      cancelText: l10n.translate('cancel'),
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(challengeDetailNotifierProvider(challengeId).notifier)
          .leaveChallenge();

      if (!context.mounted) return;

      getSuccessSnackBar(
        context,
        'challenge-left',
      );
    }
  }

  Future<void> _showUpdateProgressDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final controller = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          title: Text(l10n.translate('update-progress')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.translate('new-value'),
              hintText: l10n.translate('enter-new-value'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: Text(l10n.translate('update')),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      await ref
          .read(challengeDetailNotifierProvider(challengeId).notifier)
          .updateProgress(result);

      if (!context.mounted) return;

      getSuccessSnackBar(
        context,
        'progress-updated',
      );
    }
  }
}

