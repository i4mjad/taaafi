import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leaderboard section
            _buildLeaderboardSection(context, theme, l10n),

            verticalSpace(Spacing.points24),

            // Active challenges section
            _buildActiveChallengesSection(context, theme, l10n),

            verticalSpace(Spacing.points24),

            // Current tasks section
            _buildCurrentTasksSection(context, theme, l10n),

            verticalSpace(Spacing.points24),
          ],
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
            'لوحة النتائج',
            style: TextStyles.h5.copyWith(
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
      padding: EdgeInsets.symmetric(vertical: Spacing.points8.value),
      child: Row(
        children: [
          // Rank and name (left side)
          Expanded(
            child: Row(
              children: [
                Text(
                  participant.pointsText,
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          horizontalSpace(Spacing.points12),

          // Avatar and name (center-right)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: participant.avatarColor,
              shape: BoxShape.circle,
            ),
          ),

          horizontalSpace(Spacing.points8),

          // Trophy icon for top performers
          if (participant.rank <= 3)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getTrophyColor(participant.rank),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.crown,
                size: 12,
                color: Colors.white,
              ),
            ),

          horizontalSpace(Spacing.points8),

          // Name (rightmost)
          Text(
            participant.name,
            style: TextStyles.body.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w500,
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
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
          ),
          verticalSpace(Spacing.points16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: challenges.length,
              separatorBuilder: (context, index) =>
                  horizontalSpace(Spacing.points12),
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _buildActiveChallengeCard(context, theme, challenge);
              },
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
    return WidgetsContainer(
      width: 140,
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: challenge.progressPercentage / 100,
                  backgroundColor: theme.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.success[500]!),
                  strokeWidth: 4,
                ),
                Text(
                  '${challenge.progressPercentage}%',
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          verticalSpace(Spacing.points12),

          // Challenge title
          Text(
            challenge.title,
            style: TextStyles.caption.copyWith(
              color: theme.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          verticalSpace(Spacing.points4),

          // Date
          Text(
            challenge.dateText,
            style: TextStyles.small.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTasksSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final tasks = _getDemoCurrentTasks();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.points16.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مهامك الحالية',
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
          ),
          verticalSpace(Spacing.points16),
          Column(
            children: tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return _buildCurrentTaskItem(context, theme, task, index + 1);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTaskItem(
    BuildContext context,
    CustomThemeData theme,
    CurrentTask task,
    int number,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: Spacing.points12.value),
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(
          color: task.isCompleted ? theme.success[200]! : theme.grey[200]!,
          width: 1,
        ),
        child: Row(
          children: [
            // Task content (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    task.subtitle,
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  if (task.statusText != null) ...[
                    verticalSpace(Spacing.points4),
                    Text(
                      task.statusText!,
                      style: TextStyles.small.copyWith(
                        color: task.statusColor ?? theme.warn[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            horizontalSpace(Spacing.points16),

            // Number and checkbox (right side)
            Column(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? theme.success[500]
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? theme.success[500]!
                          : theme.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: task.isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),

                verticalSpace(Spacing.points8),

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
                      style: TextStyles.caption.copyWith(
                        color: theme.primary[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrophyColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
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
        title: 'تحدي كتابة المذكرات',
        progressPercentage: 28,
        dateText: 'ينتهي 28 يناير',
      ),
      ActiveChallenge(
        id: '2',
        title: 'تحدي المتابعة اليومية',
        progressPercentage: 28,
        dateText: 'ينتهي 28 يناير',
      ),
      ActiveChallenge(
        id: '3',
        title: 'تحدي التأمل',
        progressPercentage: 28,
        dateText: 'ينتهي 28 يناير',
      ),
    ];
  }

  List<CurrentTask> _getDemoCurrentTasks() {
    return [
      CurrentTask(
        id: '1',
        title: 'اكتب مذكرتك اليومية',
        subtitle: 'تحدي كتابة المذكرات',
        isCompleted: true,
      ),
      CurrentTask(
        id: '2',
        title: 'اقرأ المتابعة اليومية',
        subtitle: 'تحدي المتابعة اليومية',
        isCompleted: false,
        statusText: 'متبقي 8 ساعات و 28 دقيقة',
      ),
      CurrentTask(
        id: '3',
        title: 'اضف المتابعة اليومية',
        subtitle: 'تحدي المتابعة اليومية',
        isCompleted: false,
        statusText: 'متبقي ساعتان و 28 دقيقة',
        statusColor: Colors.red,
      ),
    ];
  }
}
