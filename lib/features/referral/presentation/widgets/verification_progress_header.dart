import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../../../core/shared_widgets/container.dart';

class VerificationProgressHeader extends ConsumerWidget {
  final int completedItems;
  final int totalItems;

  const VerificationProgressHeader({
    super.key,
    required this.completedItems,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final percentage = (completedItems / totalItems) * 100;
    final isComplete = completedItems == totalItems;

    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      backgroundColor: isComplete ? theme.success[50] : theme.primary[50],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isComplete ? theme.success[200]! : theme.primary[200]!,
        width: 1.5,
      ),
      cornerSmoothing: 1,
      child: Column(
        children: [
          // Emoji indicator
          Text(
            isComplete ? '🎉' : '⏳',
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 12),

          // Progress text
          Text(
            l10n.translate('referral.checklist.progress')
                .replaceAll('{completed}', completedItems.toString())
                .replaceAll('{total}', totalItems.toString()),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalItems, (index) {
              final isCompleted = index < completedItems;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? (isComplete ? theme.success[600] : theme.primary[600])
                      : theme.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedItems / totalItems,
              minHeight: 8,
              backgroundColor: theme.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? theme.success[600]! : theme.primary[600]!,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Percentage text
          Text(
            '${percentage.round()}%',
            style: TextStyles.h6.copyWith(
              color: isComplete ? theme.success[700] : theme.primary[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Motivational message
          Text(
            _getMotivationalMessage(completedItems, totalItems, l10n),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(
      int completed, int total, AppLocalizations l10n) {
    if (completed == total) {
      return l10n.translate('referral.checklist.all_complete_message');
    } else if (completed >= total * 0.7) {
      return l10n.translate('referral.checklist.almost_there');
    } else if (completed >= total * 0.4) {
      return l10n.translate('referral.checklist.great_progress');
    } else if (completed > 0) {
      return l10n.translate('referral.checklist.keep_going');
    } else {
      return l10n.translate('referral.checklist.subtitle');
    }
  }
}

