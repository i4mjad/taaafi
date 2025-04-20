import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/streak_display_notifier.dart';

class StreakSettingsSheet extends ConsumerWidget {
  const StreakSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);
    final streakDisplayMode = ref.watch(streakDisplayProvider);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('streak-settings'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),

          // Streak Display Mode
          Text(
            AppLocalizations.of(context).translate('streak-display-mode'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('streak-display-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: IntrinsicHeight(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(streakDisplayProvider.notifier)
                          .setDisplayMode(StreakDisplayMode.days);
                    },
                    child: WidgetsContainer(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor:
                          streakDisplayMode == StreakDisplayMode.days
                              ? theme.primary[50]
                              : theme.backgroundColor,
                      borderSide: BorderSide(
                        color: streakDisplayMode == StreakDisplayMode.days
                            ? theme.primary[600]!
                            : theme.grey[200]!,
                        width: 1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 16,
                                color:
                                    streakDisplayMode == StreakDisplayMode.days
                                        ? theme.primary[600]
                                        : theme.grey[600],
                              ),
                              horizontalSpace(Spacing.points4),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('days-only'),
                                  style: TextStyles.caption.copyWith(
                                    color: streakDisplayMode ==
                                            StreakDisplayMode.days
                                        ? theme.primary[600]
                                        : theme.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context)
                                .translate('days-only-description'),
                            style: TextStyles.small.copyWith(
                              color: streakDisplayMode == StreakDisplayMode.days
                                  ? theme.primary[400]
                                  : theme.grey[400],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: IntrinsicHeight(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(streakDisplayProvider.notifier)
                          .setDisplayMode(StreakDisplayMode.detailed);
                    },
                    child: WidgetsContainer(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor:
                          streakDisplayMode == StreakDisplayMode.detailed
                              ? theme.primary[50]
                              : theme.backgroundColor,
                      borderSide: BorderSide(
                        color: streakDisplayMode == StreakDisplayMode.detailed
                            ? theme.primary[600]!
                            : theme.grey[200]!,
                        width: 1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 16,
                                color: streakDisplayMode ==
                                        StreakDisplayMode.detailed
                                    ? theme.primary[600]
                                    : theme.grey[600],
                              ),
                              horizontalSpace(Spacing.points4),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('detailed'),
                                  style: TextStyles.caption.copyWith(
                                    color: streakDisplayMode ==
                                            StreakDisplayMode.detailed
                                        ? theme.primary[600]
                                        : theme.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context)
                                .translate('detailed-description'),
                            style: TextStyles.small.copyWith(
                              color: streakDisplayMode ==
                                      StreakDisplayMode.detailed
                                  ? theme.primary[400]
                                  : theme.grey[400],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),

          // Statistics Visibility
          Text(
            AppLocalizations.of(context).translate('statistics-visibility'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('statistics-visibility-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'relapse',
                          !visibilitySettings['relapse']!,
                        );
                  },
                  text: "relapses",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['relapse']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'pornOnly',
                          !visibilitySettings['pornOnly']!,
                        );
                  },
                  text: "porn",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['pornOnly']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'mastOnly',
                          !visibilitySettings['mastOnly']!,
                        );
                  },
                  text: "mast",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['mastOnly']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'slipUp',
                          !visibilitySettings['slipUp']!,
                        );
                  },
                  text: "slips",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['slipUp']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),

          // Save button
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              await ref
                  .read(statisticsVisibilityProvider.notifier)
                  .savePreferences();
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[600],
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('save'),
                  style: TextStyles.h6.copyWith(color: theme.grey[50]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  const SettingsOption({
    required this.onTap,
    required this.text,
    required this.icon,
    required this.type,
    this.isChecked = false,
    super.key,
  });

  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final String type;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(4),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                activeColor: theme.primary[600],
                value: isChecked,
                onChanged: (value) => onTap(),
              ),
              Text(
                AppLocalizations.of(context).translate(text),
                style: TextStyles.small
                    .copyWith(color: _getIconAndTextColor(type, theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconAndTextColor(String type, CustomThemeData theme) {
    switch (type) {
      case 'error':
        return theme.error[600]!;
      case 'primary':
        return theme.primary[600]!;
      case 'warn':
        return theme.warn[600]!;
      case 'normal':
      default:
        return theme.grey[800]!;
    }
  }
}
