import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/follow_up_history_modal.dart';

class HeatMapCalendar extends ConsumerWidget {
  const HeatMapCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final heatMapAsync = ref.watch(heatMapDataProvider);

    return WidgetsContainer(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      backgroundColor: theme.grey[50],
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context)
                    .translate('heat-map-calendar-title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points20),

          // Heat map section
          heatMapAsync.when(
            data: (followUps) =>
                _buildHeatMapSection(context, theme, followUps, ref),
            loading: () => Center(child: Spinner()),
            error: (error, _) => _buildEmptyState(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMapSection(BuildContext context, dynamic theme,
      List<dynamic> followUps, WidgetRef ref) {
    if (followUps.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title for day-of-month view
        Text(
          AppLocalizations.of(context).translate('day-of-month-patterns'),
          style: TextStyles.footnote.copyWith(
            color: theme.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points4),
        Text(
          AppLocalizations.of(context).translate('day-of-month-desc'),
          style: TextStyles.small.copyWith(
            color: theme.grey[600],
          ),
        ),
        verticalSpace(Spacing.points12),

        // Week days header (Sun to Sat)
        _buildWeekDaysHeader(context, theme),
        verticalSpace(Spacing.points8),

        // Day-of-month grid (1-31)
        _buildDayOfMonthGrid(context, theme, followUps, ref),
        verticalSpace(Spacing.points16),

        // Legend
        _buildLegend(context, theme),
      ],
    );
  }

  Widget _buildWeekDaysHeader(BuildContext context, dynamic theme) {
    final weekDays = [
      'sun-short',
      'mon-short',
      'tue-short',
      'wed-short',
      'thu-short',
      'fri-short',
      'sat-short'
    ];

    return Row(
      children: weekDays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate(day),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayOfMonthGrid(BuildContext context, dynamic theme,
      List<dynamic> followUps, WidgetRef ref) {
    // Create a map of day-of-month -> follow-up count across all time
    final Map<int, int> followUpCounts = {};
    for (var followUp in followUps) {
      final followUpDate = followUp.time as DateTime;
      final day = followUpDate.day;
      followUpCounts[day] = (followUpCounts[day] ?? 0) + 1;
    }

    final weeks = <Widget>[];
    var currentWeek = <Widget>[];

    // Add cells for days 1-31 (fixed grid)
    for (int day = 1; day <= 31; day++) {
      final followUpCount = followUpCounts[day] ?? 0;

      currentWeek.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFollowUpHistoryModal(context, ref, dayOfMonth: day);
            },
            child: Container(
              height: 32,
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getHeatColor(theme, followUpCount),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: day == DateTime.now().day
                      ? theme.primary[500]!
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyles.small.copyWith(
                    color: followUpCount > 0 ? theme.grey[50] : theme.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // If we've filled a week (7 days)
      if (currentWeek.length == 7) {
        weeks.add(Row(children: currentWeek));
        currentWeek = <Widget>[];
      }
    }

    // Add any remaining days to the last week and fill empty slots
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(Expanded(child: SizedBox(height: 32)));
      }
      weeks.add(Row(children: currentWeek));
    }

    return Column(
      children: weeks
          .map((week) => Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: week,
              ))
          .toList(),
    );
  }

  Color _getHeatColor(dynamic theme, int followUpCount) {
    if (followUpCount == 0) {
      return theme.grey[200]!;
    } else if (followUpCount == 1) {
      return theme.warn[300]!;
    } else if (followUpCount <= 3) {
      return theme.error[400]!;
    } else {
      return theme.error[600]!;
    }
  }

  Widget _buildLegend(BuildContext context, dynamic theme) {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context).translate('less'),
          style: TextStyles.small.copyWith(color: theme.grey[600]),
        ),
        horizontalSpace(Spacing.points8),
        ...List.generate(
            4,
            (index) => Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: [
                        theme.grey[200]!,
                        theme.warn[300]!,
                        theme.error[400]!,
                        theme.error[600]!,
                      ][index],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
        horizontalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('more'),
          style: TextStyles.small.copyWith(color: theme.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendar,
            color: theme.grey[400],
            size: 32,
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate('heat-map-empty'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFollowUpHistoryModal(BuildContext context, WidgetRef ref,
      {DateTime? date, int? days, int? dayOfMonth}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => FollowUpHistoryModal(
        date: date,
        days: days,
        dayOfMonth: dayOfMonth,
      ),
    );
  }
}
