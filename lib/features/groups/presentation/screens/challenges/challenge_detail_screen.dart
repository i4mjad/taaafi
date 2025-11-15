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
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_detail_notifier.dart';
import 'package:reboot_app_3/features/groups/application/group_chat_providers.dart';

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
    final detailAsync = ref.watch(challengeDetailNotifierProvider(challengeId));
    final isAdminAsync = ref.watch(isCurrentUserGroupAdminProvider(groupId));
    final isAdmin = isAdminAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: detailAsync.when(
          data: (state) => Text(
            state.challenge?.name ?? l10n.translate('challenge'),
            style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
          ),
          loading: () => Text(
            l10n.translate('challenge'),
            style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
          ),
          error: (_, __) => Text(
            l10n.translate('challenge'),
            style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
        titleSpacing: 0,
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.editChallenge.name,
                      pathParameters: {
                        'groupId': groupId,
                        'challengeId': challengeId,
                      },
                    );
                  },
                ),
              ]
            : null,
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
              ref
                  .read(challengeDetailNotifierProvider(challengeId).notifier)
                  .refresh();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(theme, l10n, challenge),

                  verticalSpace(Spacing.points16),

                  // Stats Card
                  if (isParticipating)
                    _buildUserProgressCard(
                        theme, l10n, challenge, userParticipation),

                  verticalSpace(Spacing.points16),

                  // Tasks Checklist
                  _buildTasksSection(
                      context, ref, theme, l10n, challenge, userParticipation),

                  verticalSpace(Spacing.points16),

                  // Leaderboard Preview
                  _buildLeaderboardPreview(context, theme, l10n,
                      state.leaderboard, userParticipation),

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
      theme, AppLocalizations l10n, ChallengeEntity challenge) {
    return WidgetsContainer(
      backgroundColor:
          _getColorValue(theme, challenge.color).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: _getColorValue(theme, challenge.color).withValues(alpha: 0.3),
        width: 2,
      ),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description (if exists, otherwise show name)
          Text(
            challenge.description.isNotEmpty
                ? challenge.description
                : challenge.name,
            style: TextStyles.body.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          verticalSpace(Spacing.points12),
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
                '${challenge.getDaysRemaining()} ${l10n.translate('days')}',
                style: TextStyles.small.copyWith(color: theme.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProgressCard(theme, AppLocalizations l10n,
      ChallengeEntity challenge, userParticipation) {
    final totalTasks = challenge.tasks.length;
    final progressPercent = userParticipation.getProgressPercentage(totalTasks);
    final completedTasksCount =
        userParticipation.taskCompletions.map((c) => c.taskId).toSet().length;

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
          verticalSpace(Spacing.points8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 12,
              backgroundColor: theme.grey[200],
              valueColor: AlwaysStoppedAnimation(theme.success[600]!),
            ),
          ),
          verticalSpace(Spacing.points8),
          Text(
            '$completedTasksCount / $totalTasks ${l10n.translate('tasks')} • ${userParticipation.earnedPoints} ${l10n.translate('points')}',
            style: TextStyles.small.copyWith(color: theme.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, WidgetRef ref, theme,
      AppLocalizations l10n, ChallengeEntity challenge, userParticipation) {
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
                l10n.translate('tasks'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userParticipation != null)
                GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      RouteNames.challengeHistory.name,
                      pathParameters: {
                        'groupId': groupId,
                        'challengeId': challengeId,
                      },
                    );
                  },
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
          verticalSpace(Spacing.points16),
          ...challenge.tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final isCompletedToday =
                userParticipation?.isTaskCompletedToday(task.id) ?? false;
            final canComplete = userParticipation != null &&
                userParticipation.canCompleteTask(task.id, task.frequency);

            return _buildTaskItem(
              context,
              ref,
              theme,
              l10n,
              task,
              index + 1,
              isCompletedToday,
              canComplete,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    WidgetRef ref,
    theme,
    AppLocalizations l10n,
    ChallengeTaskEntity task,
    int number,
    bool isCompleted,
    bool canComplete,
  ) {
    final frequencyLabel = _getFrequencyLabel(l10n, task.frequency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: canComplete
                ? () {
                    ref
                        .read(challengeDetailNotifierProvider(challengeId)
                            .notifier)
                        .completeTask(task.id, task.points, task.frequency);
                  }
                : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? theme.success[600] : theme.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted ? theme.success[600]! : theme.grey[400]!,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. ${task.name}',
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$frequencyLabel • ${task.points} ${l10n.translate('points')}',
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, theme,
      AppLocalizations l10n, leaderboard, userParticipation) {
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
            l10n.translate('leaderboard'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          verticalSpace(Spacing.points8),
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
              final isCurrentUser = userParticipation != null &&
                  participant.cpId == userParticipation.cpId;

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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? theme.primary[50] : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isCurrentUser
                  ? l10n.translate('you')
                  : l10n.translate('participant'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${participant.earnedPoints} ${l10n.translate('points')}',
            style: TextStyles.smallBold.copyWith(
              color: theme.success[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      WidgetRef ref,
      theme,
      AppLocalizations l10n,
      ChallengeEntity challenge,
      bool isParticipating,
      bool isLoading) {
    if (isParticipating) {
      return SizedBox(
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
      );
    }

    // Not participating - show Join button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading || !challenge.canJoin('')
            ? null
            : () => _joinChallenge(context, ref, l10n),
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

  Future<void> _joinChallenge(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    await ref
        .read(challengeDetailNotifierProvider(challengeId).notifier)
        .joinChallenge();

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

  String _getFrequencyLabel(AppLocalizations l10n, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return l10n.translate('daily');
      case TaskFrequency.weekly:
        return l10n.translate('weekly');
      case TaskFrequency.oneTime:
        return l10n.translate('one-time');
    }
  }

  Color _getColorValue(theme, String color) {
    switch (color) {
      case 'yellow':
        return theme.warn[400]!;
      case 'coral':
        return theme.tint[400]!;
      case 'blue':
        return theme.secondary[400]!;
      case 'teal':
        return theme.primary[400]!;
      default:
        return theme.primary[400]!;
    }
  }
}
