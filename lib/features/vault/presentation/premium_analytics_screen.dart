import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/heat_map_calendar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/streak_averages_card.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/trigger_radar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/risk_clock.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/mood_correlation_chart.dart';

class PremiumAnalyticsScreen extends ConsumerWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'premium-analytics-title',
        false,
        true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            verticalSpace(Spacing.points24),

            // Streak Averages Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreakAveragesCard(),
            ),
            verticalSpace(Spacing.points20),

            // Heat Map Calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: HeatMapCalendar(),
            ),
            verticalSpace(Spacing.points20),

            // Trigger Radar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TriggerRadar(),
            ),
            verticalSpace(Spacing.points20),

            // Risk Clock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RiskClock(),
            ),
            verticalSpace(Spacing.points20),

            // Mood Correlation Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MoodCorrelationChart(),
            ),
            verticalSpace(Spacing.points32),
          ],
        ),
      ),
    );
  }
}
