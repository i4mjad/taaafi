import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Chart data
  late List<FlSpot> _chartSpots = [];
  late double _maxX = 0;
  late double _maxY = 0;

  // Zoom functionality
  double _zoomLevel = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;

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
      _calculateChartData(periods);

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

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.5).clamp(1.0, 5.0);
    });
    HapticFeedback.lightImpact();
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.5).clamp(1.0, 5.0);
    });
    HapticFeedback.lightImpact();
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _panX = 0.0;
      _panY = 0.0;
    });
    HapticFeedback.lightImpact();
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

  /// Calculates chart data points for visualizing streak periods
  ///
  /// The algorithm creates a continuous line chart where:
  /// - Each period is represented as a line segment
  /// - X-axis shows cumulative total days across all periods
  /// - Y-axis shows days within each period (0 to period duration)
  /// - Each new period starts where the previous one ended
  ///
  /// Example calculation for 3 periods:
  /// Period 1: 34 days -> Points: (0,0) to (34,34)
  /// Period 2: 15 days -> Points: (34,0) to (49,15)
  /// Period 3: 10 days (ongoing) -> Points: (49,0), (50,1), (51,2)...(59,10)
  ///
  /// Visual representation:
  /// Y (Days in Period)
  /// ^
  /// | 34 ●─────● 15 ●
  /// |   /         / ●
  /// |  /         /  ● 10
  /// | /         /   ●
  /// |/         /    ●  (ongoing)
  /// 0 ●       ●     ●
  /// +─────────────────────> X (Cumulative Days)
  ///   0    34   49   59
  void _calculateChartData(List<PeriodInfo> periods) {
    _chartSpots = [];
    double cumulativeDays = 0;

    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      final periodDays = period.duration.inDays.toDouble();

      // STEP 1: Add start point of the period
      // First period starts at origin (0,0)
      // Subsequent periods start at (cumulative_days_so_far, 0)
      if (i == 0) {
        _chartSpots.add(FlSpot(0, 0));
      } else {
        _chartSpots.add(FlSpot(cumulativeDays, 0));
      }

      // STEP 2: Calculate the cumulative days including this period
      cumulativeDays += periodDays;

      // STEP 3: Add end point(s) for the period
      if (!period.isCurrentPeriod) {
        // For completed periods: add single end point
        // Creates a straight line from start to end
        _chartSpots.add(FlSpot(cumulativeDays, periodDays));
      } else {
        // For current/ongoing period: add multiple points
        // This shows day-by-day progress and indicates it's still active
        // Each point represents one day of progress
        for (int day = 1; day <= periodDays.toInt(); day++) {
          // X: cumulative days up to this day
          // Y: day number within current period
          final x = cumulativeDays - periodDays + day;
          final y = day.toDouble();
          _chartSpots.add(FlSpot(x, y));
        }
      }
    }

    // STEP 4: Calculate chart bounds
    // X-axis max is the total cumulative days
    _maxX = cumulativeDays;

    // Find the longest period for Y-axis max
    _maxY = periods
        .map((p) => p.duration.inDays.toDouble())
        .reduce((a, b) => a > b ? a : b);

    // STEP 5: Ensure minimum chart size for better visibility
    _maxX = _maxX < 10 ? 10 : _maxX;
    _maxY = _maxY < 10 ? 10 : _maxY;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return SafeArea(
      child: Container(
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
                      : Column(
                          children: [
                            // Chart with title
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Chart title
                                  Text(
                                    localization
                                        .translate("streak-progress-chart"),
                                    style: TextStyles.body.copyWith(
                                      color: theme.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  verticalSpace(Spacing.points8),
                                  // Chart legend
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: followUpColors[
                                              widget.followUpType],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      horizontalSpace(Spacing.points8),
                                      Text(
                                        localization
                                            .translate("cumulative-days"),
                                        style: TextStyles.caption.copyWith(
                                          color: theme.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  verticalSpace(Spacing.points12),
                                  // Chart with zoom controls
                                  Container(
                                    height: 280,
                                    child: Stack(
                                      children: [
                                        // Chart container with proper clipping
                                        ClipRect(
                                          child: Container(
                                            margin: EdgeInsets.only(
                                                right: 50,
                                                top: 20,
                                                bottom:
                                                    10), // Space for controls and tooltips
                                            child: _buildChart(
                                                theme, localization, context),
                                          ),
                                        ),
                                        // Zoom controls
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.backgroundColor
                                                  .withValues(alpha: 0.95),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme.grey[400]!
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: EdgeInsets.all(4),
                                            child: Column(
                                              children: [
                                                // Zoom In
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: theme.backgroundColor
                                                        .withValues(alpha: 0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color:
                                                            theme.grey[300]!),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.grey[400]!
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    onPressed: _zoomLevel < 5.0
                                                        ? _zoomIn
                                                        : null,
                                                    icon: Icon(
                                                      LucideIcons.plus,
                                                      size: 16,
                                                      color: _zoomLevel < 5.0
                                                          ? theme.grey[700]
                                                          : theme.grey[400],
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                                verticalSpace(Spacing.points4),
                                                // Zoom Out
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: theme.backgroundColor
                                                        .withValues(alpha: 0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color:
                                                            theme.grey[300]!),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.grey[400]!
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    onPressed: _zoomLevel > 1.0
                                                        ? _zoomOut
                                                        : null,
                                                    icon: Icon(
                                                      LucideIcons.minus,
                                                      size: 16,
                                                      color: _zoomLevel > 1.0
                                                          ? theme.grey[700]
                                                          : theme.grey[400],
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                                verticalSpace(Spacing.points4),
                                                // Reset Zoom
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: theme.backgroundColor
                                                        .withValues(alpha: 0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color:
                                                            theme.grey[300]!),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.grey[400]!
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    onPressed:
                                                        _zoomLevel != 1.0 ||
                                                                _panX != 0 ||
                                                                _panY != 0
                                                            ? _resetZoom
                                                            : null,
                                                    icon: Icon(
                                                      LucideIcons.home,
                                                      size: 16,
                                                      color:
                                                          _zoomLevel != 1.0 ||
                                                                  _panX != 0 ||
                                                                  _panY != 0
                                                              ? theme.grey[700]
                                                              : theme.grey[400],
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Pan controls when zoomed in
                                        if (_zoomLevel > 1.0)
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme.backgroundColor
                                                    .withValues(alpha: 0.95),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.grey[400]!
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(4),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Up arrow
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    child: IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          final maxPanY = (260 *
                                                                  (_zoomLevel -
                                                                      1)) /
                                                              2;
                                                          _panY = (_panY + 20)
                                                              .clamp(-maxPanY,
                                                                  maxPanY);
                                                        });
                                                        HapticFeedback
                                                            .selectionClick();
                                                      },
                                                      icon: Icon(
                                                        LucideIcons.chevronUp,
                                                        size: 12,
                                                        color: theme.grey[700],
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // Left arrow
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        child: IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              final maxPanX = (MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      (_zoomLevel -
                                                                          1)) /
                                                                  2;
                                                              _panX = (_panX +
                                                                      20)
                                                                  .clamp(
                                                                      -maxPanX,
                                                                      maxPanX);
                                                            });
                                                            HapticFeedback
                                                                .selectionClick();
                                                          },
                                                          icon: Icon(
                                                            LucideIcons
                                                                .chevronLeft,
                                                            size: 12,
                                                            color:
                                                                theme.grey[700],
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ),
                                                      // Right arrow
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        child: IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              final maxPanX = (MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      (_zoomLevel -
                                                                          1)) /
                                                                  2;
                                                              _panX = (_panX -
                                                                      20)
                                                                  .clamp(
                                                                      -maxPanX,
                                                                      maxPanX);
                                                            });
                                                            HapticFeedback
                                                                .selectionClick();
                                                          },
                                                          icon: Icon(
                                                            LucideIcons
                                                                .chevronRight,
                                                            size: 12,
                                                            color:
                                                                theme.grey[700],
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // Down arrow
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    child: IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          final maxPanY = (260 *
                                                                  (_zoomLevel -
                                                                      1)) /
                                                              2;
                                                          _panY = (_panY - 20)
                                                              .clamp(-maxPanY,
                                                                  maxPanY);
                                                        });
                                                        HapticFeedback
                                                            .selectionClick();
                                                      },
                                                      icon: Icon(
                                                        LucideIcons.chevronDown,
                                                        size: 12,
                                                        color: theme.grey[700],
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        // Zoom level indicator
                                        if (_zoomLevel != 1.0)
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.grey[900]!
                                                    .withValues(alpha: 0.8),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${(_zoomLevel * 100).toInt()}%',
                                                style:
                                                    TextStyles.caption.copyWith(
                                                  color: theme.grey[100],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Custom Segmented Button
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: CustomSegmentedButton(
                                options: _segmentedOptions,
                                selectedOption: _selectedOption,
                                onChanged: _onSegmentedButtonChanged,
                              ),
                            ),

                            verticalSpace(Spacing.points16),

                            // List of periods
                            Expanded(
                              child: _buildPeriodsList(
                                  theme, localization, locale),
                            ),
                          ],
                        ),
            ),
          ],
        ),
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

  Widget _buildChart(CustomThemeData theme, AppLocalizations localization,
      BuildContext context) {
    final color = followUpColors[widget.followUpType] ?? theme.primary;

    return ClipRect(
      child: GestureDetector(
        onPanStart: (details) {
          // Start panning when zoomed in
        },
        onPanUpdate: (details) {
          if (_zoomLevel > 1.0 && details.delta.distance > 3.0) {
            setState(() {
              // More responsive pan with larger movement
              final sensitivity = 1.5;
              final maxPanX =
                  (MediaQuery.of(context).size.width * (_zoomLevel - 1)) / 2;
              final maxPanY = (260 * (_zoomLevel - 1)) / 2;

              _panX = (_panX - details.delta.dx * sensitivity)
                  .clamp(-maxPanX, maxPanX);
              _panY = (_panY + details.delta.dy * sensitivity)
                  .clamp(-maxPanY, maxPanY);
            });
          }
        },
        onPanEnd: (details) {
          // Pan ended
        },
        child: Transform.scale(
          scale: _zoomLevel,
          child: Transform.translate(
            offset: Offset(_panX, _panY),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 260,
              child: LineChart(
                LineChartData(
                  clipData: FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _maxY > 50 ? 10 : 5,
                    verticalInterval: _maxX > 50 ? 10 : 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: theme.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval: _maxX > 50 ? 10 : 5,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _maxY > 50 ? 10 : 5,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: theme.grey[300]!),
                  ),
                  minX: 0,
                  maxX: _maxX * 1.1,
                  minY: 0,
                  maxY: _maxY * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartSpots,
                      isCurved: false,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Find if this is a period boundary point
                          bool isPeriodBoundary = false;
                          double runningDays = 0;

                          for (int i = 0; i < _periods.length; i++) {
                            final periodDays =
                                _periods[i].duration.inDays.toDouble();

                            // Check if this is the start of a period (y=0)
                            if (spot.x == runningDays && spot.y == 0) {
                              isPeriodBoundary = true;
                              break;
                            }

                            runningDays += periodDays;

                            // Check if this is the end of a period
                            if (spot.x == runningDays && spot.y == periodDays) {
                              isPeriodBoundary = true;
                              break;
                            }
                          }

                          if (isPeriodBoundary) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: theme.backgroundColor,
                            );
                          }

                          // For ongoing streak points, show smaller dots
                          if (index == _chartSpots.length - 1 &&
                              _periods.isNotEmpty &&
                              _periods.last.isCurrentPeriod) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: color.withValues(alpha: 0.8),
                              strokeWidth: 1,
                              strokeColor: theme.backgroundColor,
                            );
                          }

                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => theme.grey[900]!,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: EdgeInsets.all(8),
                      tooltipMargin: 8,
                      maxContentWidth: 200,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          // Tooltip shows:
                          // - Total X: Cumulative days across all periods
                          // - Day Y: Current day within the active period
                          return LineTooltipItem(
                            '${localization.translate("total")}: ${spot.x.toInt()} ${localization.translate("days")}\n${localization.translate("day")} ${spot.y.toInt()}',
                            TextStyles.caption.copyWith(
                              color: theme.grey[100],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
