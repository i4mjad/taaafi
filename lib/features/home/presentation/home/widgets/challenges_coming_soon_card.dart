import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class ChallengesComingSoonCard extends ConsumerWidget {
  const ChallengesComingSoonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header - Icon, Title, and Badge in one row
        Row(
          children: [
            WidgetsContainer(
              padding: const EdgeInsets.all(8),
              backgroundColor: theme.tint[50],
              borderSide: BorderSide(color: theme.tint[600]!),
              borderRadius: BorderRadius.circular(8),
              child: Icon(
                LucideIcons.target,
                color: theme.tint[600],
                size: 20,
              ),
            ),
            horizontalSpace(Spacing.points8),
            Expanded(
              child: Text(
                localization.translate("challenges_coming_soon_title"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.tint[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                localization.translate("soon"),
                style: TextStyles.caption.copyWith(
                  color: theme.tint[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Description in its own row with full width
        Text(
          localization.translate("challenges_coming_soon_description"),
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        verticalSpace(Spacing.points16),

        // Challenge Features Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.tint[25],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.tint[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.translate("whats_coming"),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Compact feature list
              _buildCompactFeature(
                context,
                theme,
                localization,
                icon: LucideIcons.calendar,
                title: localization.translate('challenges_feature_daily_goals'),
              ),
              const SizedBox(height: 8),
              _buildCompactFeature(
                context,
                theme,
                localization,
                icon: LucideIcons.users,
                title: localization.translate('challenges_feature_community'),
              ),
              const SizedBox(height: 8),
              _buildCompactFeature(
                context,
                theme,
                localization,
                icon: LucideIcons.trophy,
                title: localization.translate('challenges_feature_rewards'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFeature(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localization, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.tint[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyles.caption.copyWith(
              color: theme.grey[700],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
