import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_layout_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';

class CompactStreaksView extends ConsumerWidget {
  const CompactStreaksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final streaksState = ref.watch(streakNotifierProvider);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);
    final vaultLayoutSettings = ref.watch(vaultLayoutProvider);

    // Hide entire section if currentStreaks is disabled in vault layout
    if (vaultLayoutSettings.homeElementsVisibility['currentStreaks'] != true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localization.translate("current-streaks"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pushNamed(RouteNames.vault.name);
                },
                child: Row(
                  children: [
                    Text(
                      localization.translate("view-journey"),
                      style: TextStyles.small.copyWith(
                        color: theme.primary[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: theme.primary[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points12),
        streaksState.when(
          data: (streakData) {
            // Create all possible streaks
            final allStreaks = [
              if (visibilitySettings['relapse'] == true)
                _StreakData(
                  label: localization.translate("relapse-free"),
                  value: streakData.relapseStreak,
                  color: followUpColors[FollowUpType.relapse]!,
                  icon: Icons.check_circle_outline,
                ),
              if (visibilitySettings['pornOnly'] == true)
                _StreakData(
                  label: localization.translate("porn-free"),
                  value: streakData.pornOnlyStreak,
                  color: followUpColors[FollowUpType.pornOnly]!,
                  icon: Icons.visibility_off_outlined,
                ),
              if (visibilitySettings['mastOnly'] == true)
                _StreakData(
                  label: localization.translate("clean-days"),
                  value: streakData.mastOnlyStreak,
                  color: followUpColors[FollowUpType.mastOnly]!,
                  icon: Icons.self_improvement_outlined,
                ),
              if (visibilitySettings['slipUp'] == true)
                _StreakData(
                  label: localization.translate("slip-up-free"),
                  value: streakData.slipUpStreak,
                  color: followUpColors[FollowUpType.slipUp]!,
                  icon: Icons.warning_amber_outlined,
                ),
            ];

            final streaks = allStreaks;

            // If no streaks are visible, show empty state
            if (streaks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localization.translate("no-streaks-visible"),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  children: streaks.map((streak) {
                    final index = streaks.indexOf(streak);
                    return Row(
                      children: [
                        _StreakCard(streakData: streak),
                        if (index < streaks.length - 1)
                          horizontalSpace(Spacing.points12),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primary[500],
                strokeWidth: 2,
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                localization.translate("error-loading-streaks"),
                style: TextStyles.small.copyWith(color: theme.error[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakData {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StreakData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _StreakCard extends StatelessWidget {
  final _StreakData streakData;

  const _StreakCard({
    required this.streakData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SizedBox(
      width: 100,
      child: WidgetsContainer(
        width: 100,
        backgroundColor: streakData.color.withValues(alpha: 0.1),
        borderSide: BorderSide(
          color: streakData.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: streakData.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  streakData.icon,
                  color: streakData.color,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${streakData.value}',
                style: TextStyles.h6.copyWith(
                  color: streakData.color,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  streakData.label,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
