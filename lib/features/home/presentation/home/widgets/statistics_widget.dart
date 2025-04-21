import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/home/data/statistics_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/streak_display_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/detailed_streak_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/streak_settings_sheet.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';
import 'dart:async';
import 'package:reboot_app_3/features/home/application/streak_service.dart';

class StatisticsWidget extends ConsumerWidget {
  const StatisticsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _StatisticsContent();
  }
}

class _StatisticsContent extends ConsumerStatefulWidget {
  const _StatisticsContent();

  @override
  _StatisticsContentState createState() => _StatisticsContentState();
}

class _StatisticsContentState extends ConsumerState<_StatisticsContent> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final streaksState = ref.watch(streakNotifierProvider);

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          verticalSpace(Spacing.points24),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 16),
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
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return StreakSettingsSheet();
                      },
                    );
                  },
                  child: Text(
                    localization.translate("customize"),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
          verticalSpace(Spacing.points4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurrentStreaksWidget(),
                // verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context).translate("statistics"),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
                UserStatisticsWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentStreaksWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final streakState = ref.watch(streakNotifierProvider);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);
    final displayMode = ref.watch(streakDisplayProvider);
    final followUpsState = ref.watch(followUpsProvider);

    // Watch the detailed streaks
    final detailedStreaks = ref.watch(detailedStreakProvider);

    return streakState.when(
      data: (data) {
        // For days-only mode, use the original horizontal layout
        if (displayMode == StreakDisplayMode.days) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visibilitySettings['relapse']!)
                  Expanded(
                    child: WidgetsContainer(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(
                          color: followUpColors[FollowUpType.relapse]!,
                          width: 0.75),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${data.relapseStreak}",
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localization.translate("day"),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            localization.translate("current-streak"),
                            textAlign: TextAlign.center,
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (visibilitySettings['relapse']! &&
                    (visibilitySettings['pornOnly']! ||
                        visibilitySettings['mastOnly']! ||
                        visibilitySettings['slipUp']!))
                  horizontalSpace(Spacing.points8),
                if (visibilitySettings['pornOnly']!)
                  Expanded(
                    child: WidgetsContainer(
                      padding: EdgeInsets.all(12),
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(
                          color: followUpColors[FollowUpType.pornOnly]!,
                          width: 0.75),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${data.pornOnlyStreak}",
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localization.translate("day"),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            localization.translate("free-porn-days"),
                            textAlign: TextAlign.center,
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (visibilitySettings['pornOnly']! &&
                    (visibilitySettings['mastOnly']! ||
                        visibilitySettings['slipUp']!))
                  horizontalSpace(Spacing.points8),
                if (visibilitySettings['mastOnly']!)
                  Expanded(
                    child: WidgetsContainer(
                      padding: EdgeInsets.all(12),
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(
                          color: followUpColors[FollowUpType.mastOnly]!,
                          width: 0.75),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${data.mastOnlyStreak}",
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localization.translate("day"),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            localization.translate("free-mast-days"),
                            textAlign: TextAlign.center,
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (visibilitySettings['mastOnly']! &&
                    visibilitySettings['slipUp']!)
                  horizontalSpace(Spacing.points8),
                if (visibilitySettings['slipUp']!)
                  Expanded(
                    child: WidgetsContainer(
                      padding: EdgeInsets.all(12),
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(
                          color: followUpColors[FollowUpType.slipUp]!,
                          width: 0.75),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${data.slipUpStreak}",
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localization.translate("day"),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            localization.translate("free-slips-days"),
                            textAlign: TextAlign.center,
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        // For detailed mode, use a vertical layout with full-width rows
        else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (visibilitySettings['relapse']!) ...[
                  WidgetsContainer(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(
                        color: followUpColors[FollowUpType.relapse]!,
                        width: 0.75),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localization.translate("current-streak"),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: followUpColors[FollowUpType.relapse]!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getLastFollowUpDateText(FollowUpType.relapse,
                                  followUpsState, localization),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                        verticalSpace(Spacing.points8),
                        DetailedStreakWidget(
                          initialInfo: detailedStreaks['relapse']!,
                          color: followUpColors[FollowUpType.relapse]!,
                          type: FollowUpType.relapse,
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points12),
                ],
                if (visibilitySettings['pornOnly']!) ...[
                  WidgetsContainer(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(
                        color: followUpColors[FollowUpType.pornOnly]!,
                        width: 0.75),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localization.translate("free-porn-days"),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: followUpColors[FollowUpType.pornOnly]!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getLastFollowUpDateText(FollowUpType.pornOnly,
                                  followUpsState, localization),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                        verticalSpace(Spacing.points8),
                        DetailedStreakWidget(
                          initialInfo: detailedStreaks['pornOnly']!,
                          color: followUpColors[FollowUpType.pornOnly]!,
                          type: FollowUpType.pornOnly,
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points12),
                ],
                if (visibilitySettings['mastOnly']!) ...[
                  WidgetsContainer(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(
                        color: followUpColors[FollowUpType.mastOnly]!,
                        width: 0.75),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localization.translate("free-mast-days"),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: followUpColors[FollowUpType.mastOnly]!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getLastFollowUpDateText(FollowUpType.mastOnly,
                                  followUpsState, localization),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                        verticalSpace(Spacing.points8),
                        DetailedStreakWidget(
                          initialInfo: detailedStreaks['mastOnly']!,
                          color: followUpColors[FollowUpType.mastOnly]!,
                          type: FollowUpType.mastOnly,
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points12),
                ],
                if (visibilitySettings['slipUp']!)
                  WidgetsContainer(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(
                        color: followUpColors[FollowUpType.slipUp]!,
                        width: 0.75),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localization.translate("free-slips-days"),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: followUpColors[FollowUpType.slipUp]!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getLastFollowUpDateText(FollowUpType.slipUp,
                                  followUpsState, localization),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                        verticalSpace(Spacing.points8),
                        DetailedStreakWidget(
                          initialInfo: detailedStreaks['slipUp']!,
                          color: followUpColors[FollowUpType.slipUp]!,
                          type: FollowUpType.slipUp,
                        ),
                      ],
                    ),
                  ),
                verticalSpace(Spacing.points16),
              ],
            ),
          );
        }
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 150,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  String _getLastFollowUpDateText(
      FollowUpType type,
      Map<FollowUpType, List<FollowUpModel>> followUpsState,
      AppLocalizations localization) {
    final followUps = followUpsState[type] ?? [];
    if (followUps.isEmpty) {
      return localization.translate("no-follow-ups-yet");
    }
    final lastFollowUp =
        followUps.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    return localization.translate("last-follow-up") +
        getDisplayDateTime(lastFollowUp.time, localization.locale.languageCode);
  }
}

class UserStatisticsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final statisticsState = ref.watch(statisticsNotifierProvider);

    return statisticsState.when(
      data: (data) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(16),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.heart,
                          color: theme.primary[600],
                          size: 25,
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                            "${data.daysWithoutRelapse} " +
                                localization.translate("day"),
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            )),
                        verticalSpace(Spacing.points8),
                        Text(
                          localization.translate("free-days-from-start"),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(16),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.lineChart,
                          size: 25,
                          color: theme.primary[600],
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                            "${data.longestRelapseStreak} " +
                                localization.translate("day"),
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            )),
                        verticalSpace(Spacing.points8),
                        Text(
                          localization.translate("highest-streak"),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(16),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.calendarRange,
                          size: 25,
                          color: theme.primary[600],
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                            "${data.relapsesInLast30Days} " +
                                localization.translate("relapse"),
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[800],
                            )),
                        verticalSpace(Spacing.points8),
                        Text(
                          localization.translate("relapses-30-days"),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 150,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class InformationSection extends StatelessWidget {
  final String title;
  final String description;
  final Color? dotColor;

  const InformationSection({
    super.key,
    required this.title,
    required this.description,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: dotColor ?? theme.primary[600],
            shape: BoxShape.circle,
          ),
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate(title),
                style: TextStyles.footnoteSelected,
              ),
              verticalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context).translate(description),
                style: TextStyles.small.copyWith(height: 1.2),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InformationSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    void showHomeSettings(BuildContext currentContext) {
      Navigator.pop(currentContext);
      // Use a post-frame callback to ensure the first sheet is fully dismissed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet<void>(
          context: currentContext,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return HomeSettingsSheet();
          },
        );
      });
    }

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    localization.translate("what-is-all-of-those"),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          showHomeSettings(context);
                        },
                        child: WidgetsContainer(
                          padding: EdgeInsets.all(16),
                          backgroundColor: theme.warn[50],
                          borderRadius: BorderRadius.circular(10.5),
                          width: MediaQuery.of(context).size.width,
                          borderSide:
                              BorderSide(color: theme.warn[300]!, width: 0.5),
                          child: Center(
                            child: Text(
                              localization
                                  .translate("you-can-hide-any-of-those"),
                              style: TextStyles.smallBold.copyWith(
                                color: theme.warn[900],
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      InformationSection(
                        title: "relapse",
                        description: "what-is-relapse",
                        dotColor: followUpColors[FollowUpType.relapse],
                      ),
                      verticalSpace(Spacing.points16),
                      InformationSection(
                        title: "slipUp",
                        description: "what-is-slip-up",
                        dotColor: followUpColors[FollowUpType.slipUp],
                      ),
                      verticalSpace(Spacing.points16),
                      InformationSection(
                        title: "porn-only",
                        description: "what-is-no-porn",
                        dotColor: followUpColors[FollowUpType.pornOnly],
                      ),
                      verticalSpace(Spacing.points16),
                      InformationSection(
                        title: "mast-only",
                        description: "what-is-no-mast",
                        dotColor: followUpColors[FollowUpType.mastOnly],
                      ),
                      verticalSpace(Spacing.points16),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed bottom button
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.backgroundColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: theme.grey[500]!,
                      width: 0.75,
                    ),
                    borderRadius: BorderRadius.circular(10.5),
                  ),
                ),
                child: Text(
                  localization.translate('close'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[900]!,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final followUpsProvider = StateNotifierProvider<FollowUpsNotifier,
    Map<FollowUpType, List<FollowUpModel>>>((ref) {
  final service = ref.watch(streakServiceProvider);
  return FollowUpsNotifier(service);
});

class FollowUpsNotifier
    extends StateNotifier<Map<FollowUpType, List<FollowUpModel>>> {
  final StreakService _service;
  Timer? _refreshTimer;

  FollowUpsNotifier(this._service) : super({}) {
    _initializeFollowUps();
  }

  Future<void> _initializeFollowUps() async {
    await _refreshFollowUps();
    // Refresh every 5 minutes
    _refreshTimer =
        Timer.periodic(Duration(minutes: 5), (_) => _refreshFollowUps());
  }

  Future<void> _refreshFollowUps() async {
    final types = [
      FollowUpType.relapse,
      FollowUpType.pornOnly,
      FollowUpType.mastOnly,
      FollowUpType.slipUp,
    ];

    final Map<FollowUpType, List<FollowUpModel>> newState = {};

    for (final type in types) {
      try {
        final followUps = await _service.getFollowUpsByType(type);
        newState[type] = followUps;
      } catch (e) {
        // If there's an error, keep the existing data for this type
        newState[type] = state[type] ?? [];
      }
    }

    state = newState;
  }

  Future<void> refreshFollowUps() async {
    await _refreshFollowUps();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
