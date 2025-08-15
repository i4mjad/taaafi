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
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/data/models/follow_up_colors.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_layout_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/streak_display_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/streaks/streak_periods_modal.dart';

class StreaksViewWidget extends ConsumerWidget {
  const StreaksViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final streaksState = ref.watch(streakNotifierProvider);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);
    final vaultLayoutSettings = ref.watch(vaultLayoutProvider);
    final displayMode = ref.watch(streakDisplayProvider);
    final followUpsState = ref.watch(followUpsProvider);

    // Hide entire section if currentStreaks is disabled in vault layout
    if (vaultLayoutSettings.vaultElementsVisibility['currentStreaks'] != true) {
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
            // For days-only mode, use the original horizontal layout
            if (displayMode == StreakDisplayMode.days) {
              // Create all possible streaks
              final allStreaks = [
                if (visibilitySettings['relapse'] == true)
                  _StreakData(
                    label: localization.translate("relapse-free"),
                    value: streakData.relapseStreak,
                    color: followUpColors[FollowUpType.relapse]!,
                    icon: Icons.check_circle_outline,
                    followUpType: FollowUpType.relapse,
                  ),
                if (visibilitySettings['pornOnly'] == true)
                  _StreakData(
                    label: localization.translate("porn-free"),
                    value: streakData.pornOnlyStreak,
                    color: followUpColors[FollowUpType.pornOnly]!,
                    icon: Icons.visibility_off_outlined,
                    followUpType: FollowUpType.pornOnly,
                  ),
                if (visibilitySettings['mastOnly'] == true)
                  _StreakData(
                    label: localization.translate("clean-days"),
                    value: streakData.mastOnlyStreak,
                    color: followUpColors[FollowUpType.mastOnly]!,
                    icon: Icons.self_improvement_outlined,
                    followUpType: FollowUpType.mastOnly,
                  ),
                if (visibilitySettings['slipUp'] == true)
                  _StreakData(
                    label: localization.translate("slip-up-free"),
                    value: streakData.slipUpStreak,
                    color: followUpColors[FollowUpType.slipUp]!,
                    icon: Icons.warning_amber_outlined,
                    followUpType: FollowUpType.slipUp,
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
            } else {
              // For detailed mode, use compact detailed view
              return _CompactDetailedStreaksView(
                streakData: streakData,
                visibilitySettings: visibilitySettings,
                followUpsState: followUpsState,
              );
            }
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
  final FollowUpType followUpType;

  const _StreakData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.followUpType,
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          builder: (BuildContext context) {
            return StreakPeriodsModal(followUpType: streakData.followUpType);
          },
        );
      },
      child: SizedBox(
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
      ),
    );
  }
}

class _CompactDetailedStreaksView extends ConsumerWidget {
  final dynamic streakData;
  final Map<String, bool> visibilitySettings;
  final Map<FollowUpType, List<FollowUpModel>> followUpsState;

  const _CompactDetailedStreaksView({
    required this.streakData,
    required this.visibilitySettings,
    required this.followUpsState,
  });

  IconData _getIconForFollowUpType(FollowUpType type) {
    switch (type) {
      case FollowUpType.relapse:
        return LucideIcons.heartCrack;
      case FollowUpType.pornOnly:
        return LucideIcons.play;
      case FollowUpType.mastOnly:
        return LucideIcons.hand;
      case FollowUpType.slipUp:
        return LucideIcons.planeLanding;
      case FollowUpType.none:
        return LucideIcons.clock;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final detailedStreaks = ref.watch(detailedStreakProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibilitySettings['relapse'] == true) ...[
            _CompactDetailedStreakCard(
              titleKey: "relapse-free",
              followUpType: FollowUpType.relapse,
              icon: _getIconForFollowUpType(FollowUpType.relapse),
              color: followUpColors[FollowUpType.relapse]!,
              followUpsState: followUpsState,
              initialInfo: detailedStreaks['relapse']!,
            ),
            verticalSpace(Spacing.points8),
          ],
          if (visibilitySettings['pornOnly'] == true) ...[
            _CompactDetailedStreakCard(
              titleKey: "porn-free",
              followUpType: FollowUpType.pornOnly,
              icon: _getIconForFollowUpType(FollowUpType.pornOnly),
              color: followUpColors[FollowUpType.pornOnly]!,
              followUpsState: followUpsState,
              initialInfo: detailedStreaks['pornOnly']!,
            ),
            verticalSpace(Spacing.points8),
          ],
          if (visibilitySettings['mastOnly'] == true) ...[
            _CompactDetailedStreakCard(
              titleKey: "clean-days",
              followUpType: FollowUpType.mastOnly,
              icon: _getIconForFollowUpType(FollowUpType.mastOnly),
              color: followUpColors[FollowUpType.mastOnly]!,
              followUpsState: followUpsState,
              initialInfo: detailedStreaks['mastOnly']!,
            ),
            verticalSpace(Spacing.points8),
          ],
          if (visibilitySettings['slipUp'] == true) ...[
            _CompactDetailedStreakCard(
              titleKey: "slip-up-free",
              followUpType: FollowUpType.slipUp,
              icon: _getIconForFollowUpType(FollowUpType.slipUp),
              color: followUpColors[FollowUpType.slipUp]!,
              followUpsState: followUpsState,
              initialInfo: detailedStreaks['slipUp']!,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactDetailedStreakCard extends StatelessWidget {
  final String titleKey;
  final FollowUpType followUpType;
  final IconData icon;
  final Color color;
  final Map<FollowUpType, List<FollowUpModel>> followUpsState;
  final DetailedStreakInfo initialInfo;

  const _CompactDetailedStreakCard({
    required this.titleKey,
    required this.followUpType,
    required this.icon,
    required this.color,
    required this.followUpsState,
    required this.initialInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          builder: (BuildContext context) {
            return StreakPeriodsModal(followUpType: followUpType);
          },
        );
      },
      child: WidgetsContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: color.withValues(alpha: 0.05),
        borderSide: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            horizontalSpace(Spacing.points8),
            // Title
            Expanded(
              child: Text(
                localization.translate(titleKey),
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Time units - compact inline display
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (initialInfo.months > 0) ...[
                  _InlineTimeUnit(
                    value: initialInfo.months,
                    label: localization.translate("months"),
                    color: color,
                  ),
                  horizontalSpace(Spacing.points4),
                ],
                _InlineTimeUnit(
                  value: initialInfo.days,
                  label: localization.translate("days"),
                  color: color,
                ),
                horizontalSpace(Spacing.points4),
                _InlineTimeUnit(
                  value: initialInfo.hours,
                  label: localization.translate("hours"),
                  color: color,
                ),
                if (initialInfo.months == 0 && initialInfo.days == 0) ...[
                  horizontalSpace(Spacing.points4),
                  _InlineTimeUnit(
                    value: initialInfo.minutes,
                    label: localization.translate("minutes"),
                    color: color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineTimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _InlineTimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyles.small.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        horizontalSpace(Spacing.points4),
        Text(
          label,
          style: TextStyles.small.copyWith(
            color: theme.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
