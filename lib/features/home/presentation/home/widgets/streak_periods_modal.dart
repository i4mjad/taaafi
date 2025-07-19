import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';

enum PeriodDisplayMode { detailed, summary }

class StreakPeriodsModal extends ConsumerStatefulWidget {
  final FollowUpType followUpType;

  const StreakPeriodsModal({
    super.key,
    required this.followUpType,
  });

  @override
  ConsumerState<StreakPeriodsModal> createState() => _StreakPeriodsModalState();
}

class _StreakPeriodsModalState extends ConsumerState<StreakPeriodsModal> {
  PeriodDisplayMode _displayMode = PeriodDisplayMode.summary;
  List<PeriodInfo> _periods = [];
  bool _isLoading = true;

  // Define segmented button options
  late final List<SegmentedButtonOption> _segmentedOptions;
  late SegmentedButtonOption _selectedOption;

  @override
  void initState() {
    super.initState();

    // Initialize segmented button options
    _segmentedOptions = [
      SegmentedButtonOption(
        value: 'summary',
        translationKey: 'period-summary',
      ),
      SegmentedButtonOption(
        value: 'detailed',
        translationKey: 'period-details',
      ),
    ];
    _selectedOption = _segmentedOptions[0]; // Default to summary

    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() => _isLoading = true);

    try {
      final streakService = ref.read(streakServiceProvider);
      final userFirstDate = await streakService.getUserFirstDate();
      final followUps =
          await streakService.getFollowUpsByType(widget.followUpType);

      final periods = _calculatePeriods(userFirstDate, followUps);

      setState(() {
        _periods = periods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSegmentedButtonChanged(SegmentedButtonOption option) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedOption = option;
      _displayMode = option.value == 'detailed'
          ? PeriodDisplayMode.detailed
          : PeriodDisplayMode.summary;
    });
  }

  List<PeriodInfo> _calculatePeriods(
      DateTime userFirstDate, List<FollowUpModel> followUps) {
    final periods = <PeriodInfo>[];
    final now = DateTime.now();

    // Sort follow-ups chronologically
    followUps.sort((a, b) => a.time.compareTo(b.time));

    if (followUps.isEmpty) {
      // Only one period from start to now
      periods.add(PeriodInfo(
        startDate: userFirstDate,
        endDate: now,
        isCurrentPeriod: true,
        isFirstPeriod: true,
        duration: now.difference(userFirstDate),
      ));
    } else {
      // First period: userFirstDate to first follow-up
      periods.add(PeriodInfo(
        startDate: userFirstDate,
        endDate: followUps.first.time,
        isCurrentPeriod: false,
        isFirstPeriod: true,
        duration: followUps.first.time.difference(userFirstDate),
      ));

      // Periods between follow-ups
      for (int i = 0; i < followUps.length - 1; i++) {
        periods.add(PeriodInfo(
          startDate: followUps[i].time,
          endDate: followUps[i + 1].time,
          isCurrentPeriod: false,
          isFirstPeriod: false,
          duration: followUps[i + 1].time.difference(followUps[i].time),
        ));
      }

      // Current period: last follow-up to now
      periods.add(PeriodInfo(
        startDate: followUps.last.time,
        endDate: now,
        isCurrentPeriod: true,
        isFirstPeriod: false,
        duration: now.difference(followUps.last.time),
      ));
    }

    return periods;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                verticalSpace(Spacing.points16),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.translate("streak-periods"),
                            style: TextStyles.h5.copyWith(
                              color: theme.grey[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            localization
                                .translate("streak-periods-description"),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Icon(
                        LucideIcons.x,
                        color: theme.grey[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),

                verticalSpace(Spacing.points16),

                // Custom Segmented Button
                CustomSegmentedButton(
                  options: _segmentedOptions,
                  selectedOption: _selectedOption,
                  onChanged: _onSegmentedButtonChanged,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Spinner(
                      valueColor: followUpColors[widget.followUpType],
                    ),
                  )
                : _periods.isEmpty
                    ? _buildEmptyState(theme, localization)
                    : _buildPeriodsList(theme, localization, locale),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      CustomThemeData theme, AppLocalizations localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 48,
            color: theme.grey[400],
          ),
          verticalSpace(Spacing.points16),
          Text(
            localization.translate("no-periods-yet"),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodsList(
      CustomThemeData theme, AppLocalizations localization, Locale? locale) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _periods.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.grey[200],
      ),
      itemBuilder: (context, index) {
        final period = _periods[index];
        return _buildSimplePeriodItem(
            period, theme, localization, locale, index);
      },
    );
  }

  Widget _buildSimplePeriodItem(
    PeriodInfo period,
    CustomThemeData theme,
    AppLocalizations localization,
    Locale? locale,
    int index,
  ) {
    final isCurrentPeriod = period.isCurrentPeriod;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Start date
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  "${period.startDate.day}/${period.startDate.month}/${period.startDate.year}",
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${period.startDate.hour.toString().padLeft(2, '0')}:${period.startDate.minute.toString().padLeft(2, '0')}",
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Spacer(),

          // Middle column: Progress indicator + Period info + Duration
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Progress indicator with period info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCurrentPeriod
                          ? localization.translate("current-period")
                          : period.isFirstPeriod
                              ? localization.translate("starting-period")
                              : "${localization.translate("period")} ${index + 1}",
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                verticalSpace(Spacing.points4),

                // Duration
                Text(
                  _displayMode == PeriodDisplayMode.detailed
                      ? _formatDetailedDuration(period.duration, localization)
                      : _formatSummaryDuration(period.duration, localization),
                  textAlign: TextAlign.center,
                  style: TextStyles.small.copyWith(
                    color: isCurrentPeriod
                        ? followUpColors[widget.followUpType]
                        : theme.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // End date
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  isCurrentPeriod
                      ? localization.translate("now")
                      : "${period.endDate.day}/${period.endDate.month}/${period.endDate.year}",
                  style: TextStyles.small.copyWith(
                    color: isCurrentPeriod
                        ? followUpColors[widget.followUpType]
                        : theme.grey[700],
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isCurrentPeriod)
                  Text(
                    "${period.endDate.hour.toString().padLeft(2, '0')}:${period.endDate.minute.toString().padLeft(2, '0')}",
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[500],
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailedDuration(
      Duration duration, AppLocalizations localization) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];

    if (days > 0) {
      parts.add("$days ${localization.translate("days")}");
    }
    if (hours > 0) {
      parts.add("$hours ${localization.translate("hours")}");
    }
    if (minutes > 0) {
      parts.add("$minutes ${localization.translate("minutes")}");
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add("$seconds ${localization.translate("seconds")}");
    }

    return parts.join(", ");
  }

  String _formatSummaryDuration(
      Duration duration, AppLocalizations localization) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    if (days > 0) {
      if (hours > 12) {
        return "${days + 1} ${localization.translate("days")}";
      } else {
        return "$days ${localization.translate("days")}";
      }
    } else if (hours > 0) {
      return "$hours ${localization.translate("hours")}";
    } else {
      final minutes = duration.inMinutes;
      return "$minutes ${localization.translate("minutes")}";
    }
  }
}

class PeriodInfo {
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrentPeriod;
  final bool isFirstPeriod;
  final Duration duration;

  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.isCurrentPeriod,
    required this.isFirstPeriod,
    required this.duration,
  });
}
