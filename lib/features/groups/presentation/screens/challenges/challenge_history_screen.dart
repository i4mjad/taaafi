import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_instance.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';

class ChallengeHistoryScreen extends ConsumerWidget {
  final String groupId;
  final String challengeId;

  const ChallengeHistoryScreen({
    super.key,
    required this.groupId,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    
    // Load task instances for this challenge and user
    final taskInstancesAsync = ref.watch(challengeTaskInstancesProvider(challengeId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('task-history'),
          style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: taskInstancesAsync.when(
        data: (instances) {
          if (instances.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('no-task-history'),
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(challengeTaskInstancesProvider(challengeId));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GroupedListView<ChallengeTaskInstance, DateTime>(
                elements: instances,
                groupBy: (instance) => DateTime(
                  instance.scheduledDate.year,
                  instance.scheduledDate.month,
                  instance.scheduledDate.day,
                ),
                useStickyGroupSeparators: true,
                groupSeparatorBuilder: (DateTime date) => Container(
                  color: theme.backgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    getDisplayDate(date, locale!.languageCode),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                ),
                itemBuilder: (context, instance) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTaskInstanceWidget(theme, l10n, instance),
                ),
                // DON'T sort here - we already sorted by distance from today in the service
                sort: false,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.translate('error')}: ${error.toString()}',
                style: TextStyles.body.copyWith(color: theme.error[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(challengeTaskInstancesProvider(challengeId));
                },
                child: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInstanceWidget(
    theme,
    AppLocalizations l10n,
    ChallengeTaskInstance instance,
  ) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (instance.status) {
      case TaskInstanceStatus.completed:
        backgroundColor = theme.success[50]!;
        borderColor = theme.success[200]!;
        textColor = theme.success[700]!;
        icon = LucideIcons.checkCircle2;
        statusText = l10n.translate('completed');
        break;
      case TaskInstanceStatus.missed:
        // If retroactive is allowed, show as pending (can still complete)
        if (instance.task.allowRetroactiveCompletion) {
          backgroundColor = theme.warn[50]!;
          borderColor = theme.warn[200]!;
          textColor = theme.warn[700]!;
          icon = LucideIcons.alertCircle;
          statusText = l10n.translate('can-still-complete');
        } else {
          backgroundColor = theme.error[50]!;
          borderColor = theme.error[200]!;
          textColor = theme.error[700]!;
          icon = LucideIcons.xCircle;
          statusText = l10n.translate('task-missed');
        }
        break;
      case TaskInstanceStatus.today:
        backgroundColor = theme.primary[50]!;
        borderColor = theme.primary[200]!;
        textColor = theme.primary[700]!;
        icon = LucideIcons.clock;
        statusText = l10n.translate('task-pending');
        break;
      case TaskInstanceStatus.upcoming:
        backgroundColor = theme.grey[50]!;
        borderColor = theme.grey[200]!;
        textColor = theme.grey[700]!;
        icon = LucideIcons.clock;
        statusText = l10n.translate('upcoming');
        break;
    }

    return WidgetsContainer(
      backgroundColor: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor, width: 1),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Status Icon
          Icon(
            icon,
            size: 20,
            color: textColor,
          ),
          horizontalSpace(Spacing.points12),
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instance.task.name,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  '${_getFrequencyLabel(l10n, instance.task.frequency)} • ${instance.task.points} ${l10n.translate('points')}',
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyles.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
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
}

