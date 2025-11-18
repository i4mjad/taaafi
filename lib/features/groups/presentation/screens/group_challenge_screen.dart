import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_instance.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_participation_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_detail_notifier.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

class GroupChallengeScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChallengeScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChallengeScreen> createState() =>
      _GroupChallengeScreenState();
}

class _GroupChallengeScreenState extends ConsumerState<GroupChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, l10n.translate('challenges'), false, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(Spacing.points16),

              // Leaderboard section
              _buildLeaderboardSection(context, ref, theme, l10n),

              verticalSpace(Spacing.points32),

              // Active challenges section
              _buildActiveChallengesSection(context, ref, theme, l10n),

              verticalSpace(Spacing.points32),

              // Current tasks section
              _buildCurrentTasksSection(context, ref, theme, l10n),

              verticalSpace(Spacing.points32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    // Get all active challenges and combine leaderboards
    final challengesAsync = ref.watch(activeChallengesProvider(widget.groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('leaderboard'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points16),
        challengesAsync.when(
          data: (challenges) {
            if (challenges.isEmpty) {
              return _buildEmptyState(
                theme,
                l10n,
                LucideIcons.trophy,
                'no-active-challenges',
              );
            }

            // For now, show leaderboard from first challenge
            // TODO: Combine leaderboards from all challenges
            final firstChallenge = challenges.first;
            final leaderboardAsync =
                ref.watch(challengeLeaderboardProvider(firstChallenge.id, limit: 4));

            return leaderboardAsync.when(
              data: (participants) {
                if (participants.isEmpty) {
                  return _buildEmptyState(
                    theme,
                    l10n,
                    LucideIcons.users,
                    'no-participants-yet',
                  );
                }

                return Column(
                  children: participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final participant = entry.value;
                    return Column(
                      children: [
                        _buildLeaderboardItem(context, theme, l10n, participant, index + 1),
                        if (index < participants.length - 1)
                          Divider(
                            color: theme.grey[200],
                            height: 1,
                            thickness: 0.5,
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildEmptyState(
                theme,
                l10n,
                LucideIcons.alertCircle,
                'error-loading-leaderboard',
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            theme,
            l10n,
            LucideIcons.alertCircle,
            'error-loading-challenges',
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    ChallengeParticipationEntity participant,
    int rank,
  ) {
    String rankEmoji;
    switch (rank) {
      case 1:
        rankEmoji = '🥇';
        break;
      case 2:
        rankEmoji = '🥈';
        break;
      case 3:
        rankEmoji = '🥉';
        break;
      default:
        rankEmoji = '👎🏻';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.points12.value,
        vertical: Spacing.points16.value,
      ),
      child: Row(
        children: [
          // Rank emoji
          Text(
            rankEmoji,
            style: TextStyles.h5,
          ),
          horizontalSpace(Spacing.points12),

          // Avatar
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          horizontalSpace(Spacing.points12),

          // Name
          Expanded(
            child: Text(
              l10n.translate('participant'),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[900],
              ),
            ),
          ),

          // Points
          Text(
            '${participant.earnedPoints} ${l10n.translate('points')}',
            style: TextStyles.caption.copyWith(
              color: theme.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengesSection(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final challengesAsync = ref.watch(activeChallengesProvider(widget.groupId));
    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('active-challenges'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points16),
        challengesAsync.when(
          data: (challenges) {
            if (challenges.isEmpty) {
              return _buildEmptyState(
                theme,
                l10n,
                LucideIcons.trophy,
                'no-active-challenges',
              );
            }

            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: challenges.length,
                separatorBuilder: (context, index) =>
                    horizontalSpace(Spacing.points12),
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return profileAsync.when(
                    data: (profile) {
                      if (profile == null) {
                        return _buildActiveChallengeCard(
                          context,
                          theme,
                          l10n,
                          challenge.id,
                          challenge.name,
                          0,
                          challenge.getDaysRemaining(),
                        );
                      }

                      // Get participation to calculate progress
                      final participationAsync = ref.watch(
                        userChallengeParticipationProvider(
                          challenge.id,
                          profile.id,
                        ),
                      );

                      return participationAsync.when(
                        data: (participation) {
                          final progress = participation != null
                              ? participation.getProgressPercentage(
                                  challenge.tasks.length)
                              : 0.0;

                          return _buildActiveChallengeCard(
                            context,
                            theme,
                            l10n,
                            challenge.id,
                            challenge.name,
                            progress.toInt(),
                            challenge.getDaysRemaining(),
                          );
                        },
                        loading: () => _buildActiveChallengeCard(
                          context,
                          theme,
                          l10n,
                          challenge.id,
                          challenge.name,
                          0,
                          challenge.getDaysRemaining(),
                        ),
                        error: (_, __) => _buildActiveChallengeCard(
                          context,
                          theme,
                          l10n,
                          challenge.id,
                          challenge.name,
                          0,
                          challenge.getDaysRemaining(),
                        ),
                      );
                    },
                    loading: () => _buildActiveChallengeCard(
                      context,
                      theme,
                      l10n,
                      challenge.id,
                      challenge.name,
                      0,
                      challenge.getDaysRemaining(),
                    ),
                    error: (_, __) => _buildActiveChallengeCard(
                      context,
                      theme,
                      l10n,
                      challenge.id,
                      challenge.name,
                      0,
                      challenge.getDaysRemaining(),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            theme,
            l10n,
            LucideIcons.alertCircle,
            'error-loading-challenges',
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengeCard(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    String challengeId,
    String title,
    int progressPercentage,
    int daysRemaining,
  ) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteNames.challengeDetail.name,
          pathParameters: {
            'groupId': widget.groupId,
            'challengeId': challengeId,
          },
        );
      },
      child: WidgetsContainer(
        backgroundColor: theme.secondary[50],
        borderSide: BorderSide(
          color: theme.secondary[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10.5),
        cornerSmoothing: 0.6,
        padding: EdgeInsets.all(Spacing.points12.value),
        child: SizedBox(
          width: 172,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Emoji
              Text(
                '🗓️',
                style: TextStyles.smallBold,
              ),
              verticalSpace(Spacing.points8),

              // Title
              Text(
                title,
                style: TextStyles.smallBold.copyWith(
                  color: theme.secondary[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Progress percentage
              Text(
                '$progressPercentage%',
                style: TextStyles.tinyBold.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points4),

              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.grey[100],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progressPercentage / 100,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.success[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points4),

              // Days remaining
              Text(
                '${l10n.translate('remaining')}: $daysRemaining ${l10n.translate('days')}',
                style: TextStyles.bodyTiny.copyWith(
                  color: theme.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTasksSection(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final todayTasksAsync = ref.watch(groupTodayTasksProvider(widget.groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('your-current-tasks'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points16),
        todayTasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return _buildEmptyState(
                theme,
                l10n,
                LucideIcons.checkCircle2,
                'no-tasks-today',
              );
            }

            return Column(
              children: tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final taskInstance = entry.value;
                return Column(
                  children: [
                    _buildCurrentTaskItem(
                      context,
                      ref,
                      theme,
                      l10n,
                      taskInstance,
                      index + 1,
                    ),
                    if (index < tasks.length - 1)
                      verticalSpace(Spacing.points12),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            theme,
            l10n,
            LucideIcons.alertCircle,
            'error-loading-tasks',
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTaskItem(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
    ChallengeTaskInstance taskInstance,
    int number,
  ) {
    final task = taskInstance.task;
    final isCompleted = taskInstance.status == TaskInstanceStatus.completed;

    // Calculate time remaining until end of day
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final timeRemaining = endOfDay.difference(now);

    String? timeRemainingText;
    Color? timeRemainingColor;

    if (!isCompleted) {
      if (timeRemaining.inHours > 2) {
        timeRemainingText =
            '${l10n.translate('remaining')} ${timeRemaining.inHours} ${l10n.translate('hours')} ${l10n.translate('and')} ${timeRemaining.inMinutes % 60} ${l10n.translate('minutes')}';
        timeRemainingColor = theme.warn[600];
      } else {
        timeRemainingText =
            '${l10n.translate('remaining')} ${timeRemaining.inHours} ${l10n.translate('hours')} ${l10n.translate('and')} ${timeRemaining.inMinutes % 60} ${l10n.translate('minutes')}';
        timeRemainingColor = theme.error[600];
      }
    }

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.all(Spacing.points12.value),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: isCompleted
                ? null
                : () {
                    _completeTodayTask(ref, taskInstance);
                  },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? theme.success[600] : Colors.transparent,
                border: Border.all(
                  color:
                      isCompleted ? theme.success[600]! : theme.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          horizontalSpace(Spacing.points12),

          // Number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.grey[200]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          horizontalSpace(Spacing.points12),

          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  // Get challenge name from task instance
                  l10n.translate('challenge'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                  ),
                ),
                if (timeRemainingText != null) ...[
                  verticalSpace(Spacing.points4),
                  Text(
                    timeRemainingText,
                    style: TextStyles.small.copyWith(
                      color: timeRemainingColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeTodayTask(
      WidgetRef ref, ChallengeTaskInstance taskInstance) {
    // We need to find the challenge ID from the task instance
    final challengesAsync = ref.read(activeChallengesProvider(widget.groupId));

    challengesAsync.whenData((challenges) {
      // Find the challenge that contains this task
      for (final challenge in challenges) {
        if (challenge.tasks.any((t) => t.id == taskInstance.task.id)) {
          // Found the challenge, complete the task
          ref
              .read(challengeDetailNotifierProvider(challenge.id).notifier)
              .completeTask(
                taskInstance.task.id,
                taskInstance.task.points,
                taskInstance.task.frequency,
              );
          break;
        }
      }
    });
  }

  Widget _buildEmptyState(
    CustomThemeData theme,
    AppLocalizations l10n,
    IconData icon,
    String messageKey,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.points24.value),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.grey[400],
            ),
            verticalSpace(Spacing.points16),
            Text(
              l10n.translate(messageKey),
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
