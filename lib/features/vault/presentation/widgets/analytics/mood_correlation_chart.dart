import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/application/analytics_service.dart';

class MoodCorrelationChart extends ConsumerWidget {
  const MoodCorrelationChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final moodDataAsync = ref.watch(moodCorrelationDataProvider);

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
                LucideIcons.heartHandshake,
                color: Color(0xFFEC4899),
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context)
                    .translate('mood-correlation-title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context)
                .translate('mood-relapse-correlation-desc'),
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
          verticalSpace(Spacing.points20),

          // Chart
          moodDataAsync.when(
            data: (data) {
              final totalMoodEntries =
                  data.moodCounts.values.fold(0, (sum, count) => sum + count);
              if (totalMoodEntries < 5) {
                return _buildEmptyState(context, theme);
              }
              return _buildChart(context, theme, data);
            },
            loading: () => Center(child: Spinner()),
            error: (_, __) => _buildEmptyState(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
      BuildContext context, dynamic theme, MoodCorrelationData data) {
    return Column(
      children: [
        // Chart legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
                context, theme, 'mood-entries', theme.primary[500]!),
            horizontalSpace(Spacing.points24),
            _buildLegendItem(context, theme, 'relapses', theme.error[500]!),
          ],
        ),
        verticalSpace(Spacing.points16),

        // Combined chart
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(data),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final mood = group.x - 5;
                    final moodLabel = _getMoodLabel(context, mood);
                    final value = rod.toY.toInt();
                    final label = rodIndex == 0 ? 'Mood entries' : 'Relapses';
                    return BarTooltipItem(
                      '$moodLabel\n$label: $value',
                      TextStyles.small.copyWith(color: theme.grey[50]),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse != null) {
                    HapticFeedback.lightImpact();
                  }
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final mood = value.toInt() - 5;
                      return Text(
                        mood.toString(),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: _generateBarGroups(theme, data),
            ),
          ),
        ),
        verticalSpace(Spacing.points20),

        // Correlation insight
        if (data.correlation.abs() > 0.4) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.warn[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.warn[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: theme.warn[600],
                  size: 20,
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate(data.correlation < 0
                        ? 'negative-correlation'
                        : 'correlation-insight'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _getMaxY(MoodCorrelationData data) {
    double maxMood = data.moodCounts.values
        .fold(0.0, (max, count) => count > max ? count.toDouble() : max);
    double maxRelapse = data.relapseCounts.values
        .fold(0.0, (max, count) => count > max ? count.toDouble() : max);
    return (maxMood > maxRelapse ? maxMood : maxRelapse) * 1.2;
  }

  List<BarChartGroupData> _generateBarGroups(
      dynamic theme, MoodCorrelationData data) {
    return List.generate(11, (index) {
      final mood = index - 5;
      final moodCount = data.moodCounts[mood]?.toDouble() ?? 0;
      final relapseCount = data.relapseCounts[mood]?.toDouble() ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: moodCount,
            color: theme.primary[500]!,
            width: 12,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: relapseCount,
            color: theme.error[500]!,
            width: 12,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  Widget _buildLegendItem(
      BuildContext context, dynamic theme, String labelKey, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        horizontalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate(labelKey),
          style: TextStyles.small.copyWith(
            color: theme.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.heartCrack,
              color: theme.grey[400],
              size: 32,
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate('not-enough-data'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodLabel(BuildContext context, int mood) {
    if (mood <= -4)
      return AppLocalizations.of(context).translate('mood-very-low');
    if (mood <= -2) return AppLocalizations.of(context).translate('mood-low');
    if (mood <= 2)
      return AppLocalizations.of(context).translate('mood-neutral');
    if (mood <= 4) return AppLocalizations.of(context).translate('mood-high');
    return AppLocalizations.of(context).translate('mood-very-high');
  }
}
