import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_entity.dart';

class ChallengeCardWidget extends StatelessWidget {
  final ChallengeEntity challenge;
  final VoidCallback onTap;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.grey[200]!, width: 1),
        cornerSmoothing: 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Badge + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type Badge
                _buildTypeBadge(theme, l10n),

                // Status/Days Remaining
                _buildStatusBadge(theme, l10n),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              challenge.title,
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Description
            if (challenge.description.isNotEmpty)
              Text(
                challenge.description,
                style: TextStyles.small.copyWith(
                  color: theme.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Participant Info
            Row(
              children: [
                Icon(
                  LucideIcons.users,
                  size: 16,
                  color: theme.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${challenge.participantCount} ${l10n.translate('participants')}',
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 16),

                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: theme.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${challenge.durationDays} ${l10n.translate('days')}',
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(CustomThemeData theme, AppLocalizations l10n) {
    Color badgeColor;
    IconData badgeIcon;
    String labelKey;

    switch (challenge.type) {
      case ChallengeType.duration:
        badgeColor = theme.primary[100]!;
        badgeIcon = LucideIcons.clock;
        labelKey = 'duration-challenge';
        break;
      case ChallengeType.goal:
        badgeColor = theme.success[100]!;
        badgeIcon = LucideIcons.target;
        labelKey = 'goal-challenge';
        break;
      case ChallengeType.team:
        badgeColor = theme.secondary[100]!;
        badgeIcon = LucideIcons.users;
        labelKey = 'team-challenge';
        break;
      case ChallengeType.recurring:
        badgeColor = theme.warn[100]!;
        badgeIcon = LucideIcons.repeat;
        labelKey = 'recurring-challenge';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: theme.grey[900],
          ),
          const SizedBox(width: 4),
          Text(
            l10n.translate(labelKey),
            style: TextStyles.caption.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CustomThemeData theme, AppLocalizations l10n) {
    if (challenge.status == ChallengeStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.success[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.checkCircle2,
              size: 14,
              color: theme.success[700],
            ),
            const SizedBox(width: 4),
            Text(
              l10n.translate('completed'),
              style: TextStyles.caption.copyWith(
                color: theme.success[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (challenge.isActive()) {
      final daysLeft = challenge.getDaysRemaining();
      final isEndingSoon = challenge.isEndingSoon();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isEndingSoon ? theme.warn[100] : theme.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEndingSoon ? LucideIcons.alertCircle : LucideIcons.clock,
              size: 14,
              color: isEndingSoon ? theme.warn[700] : theme.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              '$daysLeft ${l10n.translate('days-left')}',
              style: TextStyles.caption.copyWith(
                color: isEndingSoon ? theme.warn[700] : theme.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

