import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_instance.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_detail_notifier.dart';

/// Model for leaderboard participant
class LeaderboardParticipant {
  final String id;
  final String name;
  final int points;
  final String pointsText;
  final int rank;
  final Color avatarColor;

  const LeaderboardParticipant({
    required this.id,
    required this.name,
    required this.points,
    required this.pointsText,
    required this.rank,
    required this.avatarColor,
  });
}

/// Model for active challenge
class ActiveChallenge {
  final String id;
  final String title;
  final int progressPercentage;
  final String dateText;

  const ActiveChallenge({
    required this.id,
    required this.title,
    required this.progressPercentage,
    required this.dateText,
  });
}

/// Model for current task
class CurrentTask {
  final String id;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final String? statusText;
  final Color? statusColor;

  const CurrentTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.statusText,
    this.statusColor,
  });
}

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
      appBar: plainAppBar(context, ref, 'التحديات', false, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.points16.value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leaderboard section
              _buildLeaderboardSection(context, theme, l10n),

              verticalSpace(Spacing.points32),

              // Active challenges section
              _buildActiveChallengesSection(context, theme, l10n),

              verticalSpace(Spacing.points32),

              // Current tasks section
              _buildCurrentTasksSection(context, theme, l10n),

              verticalSpace(Spacing.points32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final leaderboard = _getDemoLeaderboard();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('leaderboard'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
            ),
          ),
          verticalSpace(Spacing.points16),
          WidgetsContainer(
            backgroundColor: theme.backgroundColor,
            borderSide: BorderSide(
              color: theme.grey[200]!,
              width: 1,
            ),
            child: Column(
              children: leaderboard.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                return Column(
                  children: [
                    _buildLeaderboardItem(context, theme, participant),
                    if (index < leaderboard.length - 1)
                      Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(
                            vertical: Spacing.points8.value),
                        color: theme.grey[100],
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    CustomThemeData theme,
    LeaderboardParticipant participant,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Spacing.points4.value,
        horizontal: Spacing.points4.value,
      ),
      child: Row(
        children: [
          // Trophy/Medal icon for all participants
          // Container(
          //   width: 24,
          //   height: 24,
          //   decoration: BoxDecoration(
          //     color: _getTrophyColor(participant.rank),
          //     shape: BoxShape.circle,
          //   ),
          //   child: participant.rank <= 3
          //       ? Icon(
          //           LucideIcons.crown,
          //           size: 14,
          //           color: Colors.white,
          //         )
          //       : Icon(
          //           LucideIcons.thumbsDown,
          //           size: 14,
          //           color: Colors.white,
          //         ),
          // ),

          Text(
            "🥇",
            style: TextStyles.h5,
          ),
          horizontalSpace(Spacing.points8),

          // Avatar
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: participant.avatarColor,
              shape: BoxShape.circle,
            ),
          ),

          horizontalSpace(Spacing.points4),
          // Name (right side)
          Text(
            participant.name,
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[900],
            ),
          ),
          horizontalSpace(Spacing.points8),

          // Dotted line separator
          Expanded(
            child: Container(
              height: 1,
              color: theme.grey[200],
            ),
          ),

          horizontalSpace(Spacing.points8),
          // Points (leftmost)
          Text(
            participant.pointsText,
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengesSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final challenges = _getDemoActiveChallenges();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التحديات النشطة',
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
            ),
          ),
          verticalSpace(Spacing.points16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: challenges.map((challenge) {
                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: Spacing.points4.value),
                  child: _buildActiveChallengeCard(context, theme, challenge),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard(
    BuildContext context,
    CustomThemeData theme,
    ActiveChallenge challenge,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.5; // 50% of screen width

    return SizedBox(
        width: cardWidth,
        child: WidgetsContainer(
          backgroundColor: theme.grey[50],
          borderSide: BorderSide(
            color: theme.grey[200]!,
            width: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge icon
              Container(
                padding: EdgeInsets.all(Spacing.points8.value),
                decoration: BoxDecoration(
                  color: theme.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Text("🗓️"),
              ),
              verticalSpace(Spacing.points4),

              // Challenge title
              Text(
                challenge.title,
                style: TextStyles.smallBold.copyWith(
                  color: theme.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              verticalSpace(Spacing.points8),

              // Date
              Text(
                challenge.dateText,
                style: TextStyles.small.copyWith(
                  color: theme.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ));
  }

  Widget _buildCurrentTasksSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final todayTasksAsync = ref.watch(groupTodayTasksProvider(widget.groupId));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('your-tasks-today'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
            ),
          ),
          verticalSpace(Spacing.points16),
          todayTasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return WidgetsContainer(
                  backgroundColor: theme.grey[50],
                  borderSide: BorderSide(
                    color: theme.grey[200]!,
                    width: 1,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.points24.value),
                      child: Text(
                        l10n.translate('no-tasks-today'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: tasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final taskInstance = entry.value;
                  return _buildTodayTaskItem(
                    context,
                    theme,
                    l10n,
                    taskInstance,
                    index + 1,
                  );
                }).toList(),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.all(Spacing.points24.value),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => WidgetsContainer(
              backgroundColor: theme.error[50],
              borderSide: BorderSide(
                color: theme.error[200]!,
                width: 1,
              ),
              child: Padding(
                padding: EdgeInsets.all(Spacing.points16.value),
                child: Text(
                  '${l10n.translate('error')}: ${error.toString()}',
                  style: TextStyles.small.copyWith(
                    color: theme.error[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTaskItem(
    BuildContext context,
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
    
    String timeRemainingText;
    Color timeRemainingColor;
    
    if (isCompleted) {
      timeRemainingText = '✓ ${l10n.translate('completed')}';
      timeRemainingColor = theme.success[600]!;
    } else if (timeRemaining.inHours > 0) {
      timeRemainingText = '${timeRemaining.inHours} ${l10n.translate('hours-left')}';
      timeRemainingColor = theme.warn[600]!;
    } else if (timeRemaining.inMinutes > 0) {
      timeRemainingText = '${timeRemaining.inMinutes} ${l10n.translate('minutes-left')}';
      timeRemainingColor = theme.error[600]!;
    } else {
      timeRemainingText = l10n.translate('task-expired');
      timeRemainingColor = theme.grey[500]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: Spacing.points12.value),
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Row(
          children: [
            // Task content (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    '${task.points} ${l10n.translate('points')}',
                    style: TextStyles.small.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    timeRemainingText,
                    style: TextStyles.small.copyWith(
                      color: timeRemainingColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            horizontalSpace(Spacing.points12),

            // Number and checkbox (right side)
            Row(
              children: [
                // Number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.primary[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyles.small.copyWith(
                        color: theme.primary[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                horizontalSpace(Spacing.points8),

                // Checkbox
                GestureDetector(
                  onTap: isCompleted ? null : () {
                    // Complete the task
                    // We need to get the challenge ID to complete this task
                    // This will require getting the challenge from the task instance
                    _completeTodayTask(taskInstance);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? theme.success[500]
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? theme.success[500]!
                            : theme.grey[400]!,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _completeTodayTask(ChallengeTaskInstance taskInstance) {
    // We need to find the challenge ID from the task instance
    // The challenge entity is not directly in the task instance, so we need to
    // get it from the challenges list in the group
    final challengesAsync = ref.read(activeChallengesProvider(widget.groupId));
    
    challengesAsync.whenData((challenges) {
      // Find the challenge that contains this task
      for (final challenge in challenges) {
        if (challenge.tasks.any((t) => t.id == taskInstance.task.id)) {
          // Found the challenge, complete the task
          ref.read(challengeDetailNotifierProvider(challenge.id).notifier).completeTask(
            taskInstance.task.id,
            taskInstance.task.points,
            taskInstance.task.frequency,
          );
          break;
        }
      }
    });
  }

  List<LeaderboardParticipant> _getDemoLeaderboard() {
    return [
      LeaderboardParticipant(
        id: '1',
        name: 'سيف حمد',
        points: 2808,
        pointsText: '2808 نقطة',
        rank: 1,
        avatarColor: Colors.orange,
      ),
      LeaderboardParticipant(
        id: '2',
        name: 'صقر الباين',
        points: 1203,
        pointsText: '1203 نقطة',
        rank: 2,
        avatarColor: Colors.blue,
      ),
      LeaderboardParticipant(
        id: '3',
        name: 'أحمد خلفان',
        points: 923,
        pointsText: '0923 نقطة',
        rank: 3,
        avatarColor: Colors.purple,
      ),
      LeaderboardParticipant(
        id: '4',
        name: 'يوسف يعقوب',
        points: 0,
        pointsText: '0000 نقطة',
        rank: 4,
        avatarColor: Colors.brown,
      ),
    ];
  }

  List<ActiveChallenge> _getDemoActiveChallenges() {
    return [
      ActiveChallenge(
        id: '1',
        title: 'تحدي المتابعة اليومية',
        progressPercentage: 28,
        dateText: 'متبقي: 28 يوم',
      ),
      ActiveChallenge(
        id: '2',
        title: 'تحدي كتابة المذكرات',
        progressPercentage: 28,
        dateText: 'متبقي: 28 يوم',
      ),
      ActiveChallenge(
        id: '3',
        title: 'تحدي',
        progressPercentage: 28,
        dateText: 'متبقي: 28 يوم',
      ),
    ];
  }

  List<CurrentTask> _getDemoCurrentTasks() {
    final theme = AppTheme.of(context);

    return [
      CurrentTask(
        id: '1',
        title: 'اكتب مذكرتك اليومية',
        subtitle: 'تحدي كتابة المذكرات',
        isCompleted: true,
      ),
      CurrentTask(
        id: '2',
        title: 'أضف المتابعة اليومية',
        subtitle: 'تحدي المتابعة اليومية',
        isCompleted: false,
        statusText: 'متبقي 8 ساعات و 28 دقيقة',
        statusColor: theme.warn[600],
      ),
      CurrentTask(
        id: '3',
        title: 'أضف المتابعة اليومية',
        subtitle: 'تحدي المتابعة اليومية',
        isCompleted: false,
        statusText: 'متبقي ساعتان و 28 دقيقة',
        statusColor: theme.error[500],
      ),
    ];
  }
}
