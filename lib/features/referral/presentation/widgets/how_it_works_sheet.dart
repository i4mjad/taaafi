import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';

class HowItWorksSheet extends ConsumerWidget {
  const HowItWorksSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HowItWorksSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                l10n.translate('referral.how_it_works.title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),

              // Step 1
              _buildStep(
                theme: theme,
                l10n: l10n,
                number: '1',
                emoji: '📱',
                title: l10n.translate('referral.how_it_works.step1_title'),
                description:
                    l10n.translate('referral.how_it_works.step1_description'),
              ),
              const SizedBox(height: 20),

              // Step 2
              _buildStep(
                theme: theme,
                l10n: l10n,
                number: '2',
                emoji: '✅',
                title: l10n.translate('referral.how_it_works.step2_title'),
                description:
                    l10n.translate('referral.how_it_works.step2_description'),
                checklistItems: [
                  l10n.translate('referral.how_it_works.checklist_forum_posts'),
                  l10n.translate('referral.how_it_works.checklist_interactions'),
                  l10n.translate('referral.how_it_works.checklist_group_join'),
                  l10n.translate('referral.how_it_works.checklist_activity'),
                ],
              ),
              const SizedBox(height: 20),

              // Step 3
              _buildStep(
                theme: theme,
                l10n: l10n,
                number: '3',
                emoji: '🎁',
                title: l10n.translate('referral.how_it_works.step3_title'),
                description:
                    l10n.translate('referral.how_it_works.step3_description'),
                rewards: [
                  l10n.translate('referral.how_it_works.reward_verified'),
                  l10n.translate('referral.how_it_works.reward_paid'),
                ],
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.translate('referral.how_it_works.got_it'),
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required dynamic theme,
    required AppLocalizations l10n,
    required String number,
    required String emoji,
    required String title,
    required String description,
    List<String>? checklistItems,
    List<String>? rewards,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary[500],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyles.h6.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),

              // Checklist items
              if (checklistItems != null && checklistItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: checklistItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyles.body.copyWith(
                                color: theme.primary[500],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Rewards
              if (rewards != null && rewards.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.success[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.success[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rewards.map((reward) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyles.body.copyWith(
                                color: theme.success[600],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                reward,
                                style: TextStyles.caption.copyWith(
                                  color: theme.success[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

