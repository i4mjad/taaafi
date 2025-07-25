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

class MoodCorrelationChart extends ConsumerStatefulWidget {
  const MoodCorrelationChart({super.key});

  @override
  ConsumerState<MoodCorrelationChart> createState() =>
      _MoodCorrelationChartState();
}

class _MoodCorrelationChartState extends ConsumerState<MoodCorrelationChart> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final moodDataAsync = ref.watch(moodCorrelationDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mood correlation content
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
    );
  }

  void _showHelpModal(BuildContext context, dynamic theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;

        return Container(
          height: availableHeight * 0.9,
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.primary[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: theme.primary[600],
                      size: 20,
                    ),
                    horizontalSpace(Spacing.points12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('how-to-read-mood-correlation'),
                        style: TextStyles.h5.copyWith(
                          color: theme.primary[800],
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: theme.grey[600],
                        size: 20,
                      ),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.all(6),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, 20 + mediaQuery.padding.bottom),
                  child: _buildHelpContent(context, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpContent(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart explanation
        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[800],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points12),

        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-bars-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points16),

        // Correlation score explanation
        Text(
          AppLocalizations.of(context)
              .translate('correlation-score-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[800],
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context)
              .translate('correlation-negative-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points4),
        Text(
          AppLocalizations.of(context)
              .translate('correlation-positive-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points4),
        Text(
          AppLocalizations.of(context)
              .translate('correlation-none-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points16),

        // Action tips
        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-action-tips'),
          style: TextStyles.body.copyWith(
            color: theme.grey[800],
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-negative-action'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-positive-action'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context)
              .translate('mood-correlation-none-action'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
      ],
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
                    final label = rodIndex == 0
                        ? AppLocalizations.of(context).translate('mood-entries')
                        : AppLocalizations.of(context).translate('relapses');
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
              AppLocalizations.of(context)
                  .translate('mood-correlation-minimum'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
                height: 1.4,
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
