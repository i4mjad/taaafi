import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_creation_notifier.dart';

class SelectChallengeTypeScreen extends ConsumerWidget {
  final String groupId;

  const SelectChallengeTypeScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('select-challenge-type'),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              l10n.translate('choose-challenge-type'),
              style: TextStyles.h4.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              l10n.translate('challenge-type-description'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
            ),

            const SizedBox(height: 24),

            // Challenge Type Cards
            _buildTypeCard(
              context,
              ref,
              theme,
              l10n,
              type: ChallengeType.duration,
              icon: LucideIcons.clock,
              titleKey: 'duration-challenge',
              descriptionKey: 'duration-challenge-desc',
              backgroundColor: theme.primary[50]!,
              borderColor: theme.primary[200]!,
              iconColor: theme.primary[600]!,
            ),

            verticalSpace(Spacing.points16),

            _buildTypeCard(
              context,
              ref,
              theme,
              l10n,
              type: ChallengeType.goal,
              icon: LucideIcons.target,
              titleKey: 'goal-challenge',
              descriptionKey: 'goal-challenge-desc',
              backgroundColor: theme.success[50]!,
              borderColor: theme.success[200]!,
              iconColor: theme.success[600]!,
            ),

            verticalSpace(Spacing.points16),

            _buildTypeCard(
              context,
              ref,
              theme,
              l10n,
              type: ChallengeType.team,
              icon: LucideIcons.users,
              titleKey: 'team-challenge',
              descriptionKey: 'team-challenge-desc',
              backgroundColor: theme.secondary[50]!,
              borderColor: theme.secondary[200]!,
              iconColor: theme.secondary[600]!,
            ),

            verticalSpace(Spacing.points16),

            _buildTypeCard(
              context,
              ref,
              theme,
              l10n,
              type: ChallengeType.recurring,
              icon: LucideIcons.repeat,
              titleKey: 'recurring-challenge',
              descriptionKey: 'recurring-challenge-desc',
              backgroundColor: theme.warn[50]!,
              borderColor: theme.warn[200]!,
              iconColor: theme.warn[600]!,
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    WidgetRef ref,
    theme,
    AppLocalizations l10n, {
    required ChallengeType type,
    required IconData icon,
    required String titleKey,
    required String descriptionKey,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: isComingSoon
          ? null
          : () {
              // Set the challenge type in the notifier
              ref.read(challengeCreationNotifierProvider.notifier).setType(type);

              // Navigate to create challenge screen
              context.pushReplacementNamed(
                RouteNames.createChallenge.name,
                pathParameters: {'groupId': groupId},
              );
            },
      child: WidgetsContainer(
        backgroundColor: isComingSoon ? theme.grey[100]! : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isComingSoon ? theme.grey[300]! : borderColor,
          width: 1.5,
        ),
        cornerSmoothing: 0.8,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isComingSoon ? theme.grey[200] : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isComingSoon ? theme.grey[500] : iconColor,
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
                        l10n.translate(titleKey),
                        style: TextStyles.h5.copyWith(
                          color: isComingSoon ? theme.grey[600] : theme.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.warn[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.translate('coming-soon'),
                            style: TextStyles.caption.copyWith(
                              color: theme.warn[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.translate(descriptionKey),
                    style: TextStyles.small.copyWith(
                      color: isComingSoon ? theme.grey[600] : theme.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            if (!isComingSoon)
              Icon(
                LucideIcons.chevronRight,
                size: 24,
                color: theme.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

