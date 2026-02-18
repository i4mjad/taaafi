import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';

class HelpBottomSheet extends ConsumerStatefulWidget {
  final String titleKey;
  final List<HelpSection> howToReadSections;
  final List<HelpSection>? howToUseSections;
  final IconData? icon;
  final Color? iconColor;

  const HelpBottomSheet({
    super.key,
    required this.titleKey,
    required this.howToReadSections,
    this.howToUseSections,
    this.icon,
    this.iconColor,
  });

  @override
  _HelpBottomSheetState createState() => _HelpBottomSheetState();
}

class _HelpBottomSheetState extends ConsumerState<HelpBottomSheet> {
  late SegmentedButtonOption _selectedTab;
  late List<SegmentedButtonOption> _tabOptions;

  @override
  void initState() {
    super.initState();
    _tabOptions = [
      SegmentedButtonOption(value: 'read', translationKey: 'how-to-read'),
      if (widget.howToUseSections != null)
        SegmentedButtonOption(value: 'use', translationKey: 'how-to-use'),
    ];
    _selectedTab = _tabOptions.first;
  }

  List<HelpSection> _getCurrentSections() {
    if (_selectedTab.value == 'use' && widget.howToUseSections != null) {
      return widget.howToUseSections!;
    }
    return widget.howToReadSections;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.iconColor ?? theme.primary[600],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points12),
                ],
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate(widget.titleKey),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                horizontalSpace(Spacing.points8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: theme.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          verticalSpace(Spacing.points16),

          // Segmented tabs (if applicable)
          if (widget.howToUseSections != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSegmentedButton(
                options: _tabOptions,
                selectedOption: _selectedTab,
                onChanged: (option) {
                  setState(() {
                    _selectedTab = option;
                  });
                },
              ),
            ),
            verticalSpace(Spacing.points16),
          ],

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._getCurrentSections().map(
                      (section) => _buildHelpSection(context, theme, section)),
                  verticalSpace(Spacing.points32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
      BuildContext context, CustomThemeData theme, HelpSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.titleKey.isNotEmpty) ...[
            Row(
              children: [
                if (section.icon != null) ...[
                  Icon(
                    section.icon,
                    color: section.iconColor ?? theme.primary[600],
                    size: 18,
                  ),
                  horizontalSpace(Spacing.points8),
                ],
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate(section.titleKey),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points12),
          ],

          // Content items
          ...section.items.map((item) => _buildHelpItem(context, theme, item)),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      BuildContext context, CustomThemeData theme, HelpItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WidgetsContainer(
        padding: EdgeInsets.all(16),
        backgroundColor: item.backgroundColor ?? theme.grey[50],
        borderSide: BorderSide(
          color: item.borderColor ?? theme.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.titleKey.isNotEmpty) ...[
              Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      color: item.iconColor ?? theme.primary[600],
                      size: 16,
                    ),
                    horizontalSpace(Spacing.points8),
                  ],
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate(item.titleKey),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points8),
            ],
            Text(
              AppLocalizations.of(context).translate(item.descriptionKey),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                height: 1.5,
              ),
            ),

            // Recovery benefit (if provided)
            if (item.recoveryBenefitKey.isNotEmpty) ...[
              verticalSpace(Spacing.points12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.success[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.success[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.heart,
                      color: theme.success[600],
                      size: 16,
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate(item.recoveryBenefitKey),
                        style: TextStyles.small.copyWith(
                          color: theme.success[700],
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HelpSection {
  final String titleKey;
  final List<HelpItem> items;
  final IconData? icon;
  final Color? iconColor;

  const HelpSection({
    required this.titleKey,
    required this.items,
    this.icon,
    this.iconColor,
  });
}

class HelpItem {
  final String titleKey;
  final String descriptionKey;
  final String recoveryBenefitKey;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const HelpItem({
    required this.titleKey,
    required this.descriptionKey,
    this.recoveryBenefitKey = '',
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });
}

// Static helper to show help sheets
class VaultHelpSheets {
  static void showCurrentStreaksHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'current-streaks-help-title',
        icon: LucideIcons.zap,
        iconColor: const Color(0xFF6366F1),
        howToReadSections: [
          HelpSection(
            titleKey: 'what-are-streaks',
            items: [
              HelpItem(
                titleKey: 'streak-definition',
                descriptionKey: 'streak-definition-desc',
                recoveryBenefitKey: 'streak-definition-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'streak-types-title',
            items: [
              HelpItem(
                titleKey: 'relapse-free-streak',
                descriptionKey: 'relapse-free-streak-desc',
                recoveryBenefitKey: 'relapse-free-streak-benefit',
                icon: LucideIcons.heart,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'porn-free-streak',
                descriptionKey: 'porn-free-streak-desc',
                recoveryBenefitKey: 'porn-free-streak-benefit',
                icon: LucideIcons.eye,
                iconColor: const Color(0xFF8B5CF6),
              ),
              HelpItem(
                titleKey: 'clean-days-streak',
                descriptionKey: 'clean-days-streak-desc',
                recoveryBenefitKey: 'clean-days-streak-benefit',
                icon: LucideIcons.user,
                iconColor: const Color(0xFF06B6D4),
              ),
              HelpItem(
                titleKey: 'slip-up-free-streak',
                descriptionKey: 'slip-up-free-streak-desc',
                recoveryBenefitKey: 'slip-up-free-streak-benefit',
                icon: LucideIcons.shield,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'how-to-use-streaks',
            items: [
              HelpItem(
                titleKey: 'viewing-streaks',
                descriptionKey: 'viewing-streaks-desc',
                recoveryBenefitKey: 'viewing-streaks-benefit',
                icon: LucideIcons.eye,
              ),
              HelpItem(
                titleKey: 'streak-motivation',
                descriptionKey: 'streak-motivation-desc',
                recoveryBenefitKey: 'streak-motivation-benefit',
                icon: LucideIcons.target,
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'managing-streaks',
            items: [
              HelpItem(
                titleKey: 'viewing-detailed-streaks',
                descriptionKey: 'viewing-detailed-streaks-desc',
                recoveryBenefitKey: 'viewing-detailed-streaks-benefit',
                icon: LucideIcons.eye,
                iconColor: const Color(0xFF6366F1),
              ),
              HelpItem(
                titleKey: 'switching-display-modes',
                descriptionKey: 'switching-display-modes-desc',
                recoveryBenefitKey: 'switching-display-modes-benefit',
                icon: LucideIcons.toggleLeft,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'streak-actions',
            items: [
              HelpItem(
                titleKey: 'recording-follow-ups',
                descriptionKey: 'recording-follow-ups-desc',
                recoveryBenefitKey: 'recording-follow-ups-benefit',
                icon: LucideIcons.plus,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'editing-follow-ups',
                descriptionKey: 'editing-follow-ups-desc',
                recoveryBenefitKey: 'editing-follow-ups-benefit',
                icon: LucideIcons.edit,
                iconColor: const Color(0xFF06B6D4),
              ),
              HelpItem(
                titleKey: 'deleting-follow-ups',
                descriptionKey: 'deleting-follow-ups-desc',
                recoveryBenefitKey: 'deleting-follow-ups-benefit',
                icon: LucideIcons.trash2,
                iconColor: const Color(0xFFEF4444),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'advanced-streak-management',
            items: [
              HelpItem(
                titleKey: 'resetting-streaks',
                descriptionKey: 'resetting-streaks-desc',
                recoveryBenefitKey: 'resetting-streaks-benefit',
                icon: LucideIcons.rotateCcw,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'changing-start-date',
                descriptionKey: 'changing-start-date-desc',
                recoveryBenefitKey: 'changing-start-date-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF8B5CF6),
              ),
              HelpItem(
                titleKey: 'fresh-restart',
                descriptionKey: 'fresh-restart-desc',
                recoveryBenefitKey: 'fresh-restart-benefit',
                icon: LucideIcons.refreshCw,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showStatisticsHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'statistics-help-title',
        icon: LucideIcons.pieChart,
        iconColor: const Color(0xFF8B5CF6),
        howToReadSections: [
          HelpSection(
            titleKey: 'statistics-overview',
            items: [
              HelpItem(
                titleKey: 'statistics-purpose',
                descriptionKey: 'statistics-purpose-desc',
                recoveryBenefitKey: 'statistics-purpose-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'statistics-metrics',
            items: [
              HelpItem(
                titleKey: 'total-clean-days',
                descriptionKey: 'total-clean-days-desc',
                recoveryBenefitKey: 'total-clean-days-benefit',
                icon: LucideIcons.heart,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'longest-streak-stat',
                descriptionKey: 'longest-streak-stat-desc',
                recoveryBenefitKey: 'longest-streak-stat-benefit',
                icon: LucideIcons.award,
                iconColor: const Color(0xFFEAB308),
              ),
              HelpItem(
                titleKey: 'recent-relapses',
                descriptionKey: 'recent-relapses-desc',
                recoveryBenefitKey: 'recent-relapses-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFFEF4444),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'using-statistics',
            items: [
              HelpItem(
                titleKey: 'progress-tracking',
                descriptionKey: 'progress-tracking-desc',
                recoveryBenefitKey: 'progress-tracking-benefit',
                icon: LucideIcons.trendingUp,
              ),
              HelpItem(
                titleKey: 'goal-setting',
                descriptionKey: 'goal-setting-desc',
                recoveryBenefitKey: 'goal-setting-benefit',
                icon: LucideIcons.target,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showCalendarHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'calendar-help-title',
        icon: LucideIcons.calendar,
        iconColor: const Color(0xFF06B6D4),
        howToReadSections: [
          HelpSection(
            titleKey: 'calendar-overview',
            items: [
              HelpItem(
                titleKey: 'calendar-purpose',
                descriptionKey: 'calendar-purpose-desc',
                recoveryBenefitKey: 'calendar-purpose-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF06B6D4),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'calendar-color-coding',
            items: [
              HelpItem(
                titleKey: 'clean-days-calendar',
                descriptionKey: 'clean-days-calendar-desc',
                recoveryBenefitKey: 'clean-days-calendar-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'relapse-days-calendar',
                descriptionKey: 'relapse-days-calendar-desc',
                recoveryBenefitKey: 'relapse-days-calendar-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'partial-slips-calendar',
                descriptionKey: 'partial-slips-calendar-desc',
                recoveryBenefitKey: 'partial-slips-calendar-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'using-calendar',
            items: [
              HelpItem(
                titleKey: 'pattern-recognition',
                descriptionKey: 'pattern-recognition-desc',
                recoveryBenefitKey: 'pattern-recognition-benefit',
                icon: LucideIcons.search,
              ),
              HelpItem(
                titleKey: 'day-details',
                descriptionKey: 'day-details-desc',
                recoveryBenefitKey: 'day-details-benefit',
                icon: LucideIcons.mousePointer,
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'calendar-interactions',
            items: [
              HelpItem(
                titleKey: 'adding-follow-ups',
                descriptionKey: 'adding-follow-ups-desc',
                recoveryBenefitKey: 'adding-follow-ups-benefit',
                icon: LucideIcons.plus,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'editing-day-entries',
                descriptionKey: 'editing-day-entries-desc',
                recoveryBenefitKey: 'editing-day-entries-benefit',
                icon: LucideIcons.edit,
                iconColor: const Color(0xFF06B6D4),
              ),
              HelpItem(
                titleKey: 'navigating-months',
                descriptionKey: 'navigating-months-desc',
                recoveryBenefitKey: 'navigating-months-benefit',
                icon: LucideIcons.chevronsLeftRight,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'calendar-analysis',
            items: [
              HelpItem(
                titleKey: 'identifying-patterns',
                descriptionKey: 'identifying-patterns-desc',
                recoveryBenefitKey: 'identifying-patterns-benefit',
                icon: LucideIcons.search,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'viewing-trends',
                descriptionKey: 'viewing-trends-desc',
                recoveryBenefitKey: 'viewing-trends-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'monthly-overview',
                descriptionKey: 'monthly-overview-desc',
                recoveryBenefitKey: 'monthly-overview-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF06B6D4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showPremiumFeatureHelp(BuildContext context, String featureKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: '${featureKey}-help-title',
        icon: LucideIcons.crown,
        iconColor: const Color(0xFFEAB308),
        howToReadSections: [
          HelpSection(
            titleKey: 'premium-feature-info',
            items: [
              HelpItem(
                titleKey: '${featureKey}-description',
                descriptionKey: '${featureKey}-help-desc',
                icon: LucideIcons.info,
                iconColor: const Color(0xFFEAB308),
              ),
              HelpItem(
                titleKey: 'unlock-with-plus',
                descriptionKey: 'unlock-with-plus-desc',
                icon: LucideIcons.crown,
                iconColor: const Color(0xFFEAB308),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showHeatMapCalendarHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'heat-map-calendar-help-title',
        icon: LucideIcons.calendar,
        iconColor: const Color(0xFFEF4444),
        howToReadSections: [
          HelpSection(
            titleKey: 'heat-map-overview',
            items: [
              HelpItem(
                titleKey: 'heat-map-purpose',
                descriptionKey: 'heat-map-purpose-desc',
                recoveryBenefitKey: 'heat-map-purpose-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFFEF4444),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'heat-map-color-coding',
            items: [
              HelpItem(
                titleKey: 'high-relapse-days',
                descriptionKey: 'high-relapse-days-desc',
                recoveryBenefitKey: 'high-relapse-days-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'medium-relapse-days',
                descriptionKey: 'medium-relapse-days-desc',
                recoveryBenefitKey: 'medium-relapse-days-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'low-relapse-days',
                descriptionKey: 'low-relapse-days-desc',
                recoveryBenefitKey: 'low-relapse-days-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFFEF3C7),
              ),
              HelpItem(
                titleKey: 'clean-days-heat-map',
                descriptionKey: 'clean-days-heat-map-desc',
                recoveryBenefitKey: 'clean-days-heat-map-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'heat-map-patterns',
            items: [
              HelpItem(
                titleKey: 'monthly-patterns',
                descriptionKey: 'monthly-patterns-desc',
                recoveryBenefitKey: 'monthly-patterns-benefit',
                icon: LucideIcons.trendingUp,
              ),
              HelpItem(
                titleKey: 'seasonal-patterns',
                descriptionKey: 'seasonal-patterns-desc',
                recoveryBenefitKey: 'seasonal-patterns-benefit',
                icon: LucideIcons.calendar,
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'heat-map-usage',
            items: [
              HelpItem(
                titleKey: 'identify-risk-periods',
                descriptionKey: 'identify-risk-periods-desc',
                recoveryBenefitKey: 'identify-risk-periods-benefit',
                icon: LucideIcons.search,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'plan-prevention',
                descriptionKey: 'plan-prevention-desc',
                recoveryBenefitKey: 'plan-prevention-benefit',
                icon: LucideIcons.shield,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showTriggerRadarHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'trigger-radar-help-title',
        icon: LucideIcons.radar,
        iconColor: const Color(0xFFF97316),
        howToReadSections: [
          HelpSection(
            titleKey: 'trigger-radar-overview-title',
            items: [
              HelpItem(
                titleKey: 'trigger-radar-purpose',
                descriptionKey: 'trigger-radar-overview-text',
                recoveryBenefitKey: 'trigger-radar-purpose-benefit',
                icon: LucideIcons.radar,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'trigger-radar-scale-title',
            items: [
              HelpItem(
                titleKey: 'scale-100-percent',
                descriptionKey: 'scale-100-percent-desc',
                recoveryBenefitKey: 'scale-100-percent-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'scale-75-percent',
                descriptionKey: 'scale-75-percent-desc',
                recoveryBenefitKey: 'scale-75-percent-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'scale-50-percent',
                descriptionKey: 'scale-50-percent-desc',
                recoveryBenefitKey: 'scale-50-percent-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFFEAB308),
              ),
              HelpItem(
                titleKey: 'scale-25-percent',
                descriptionKey: 'scale-25-percent-desc',
                recoveryBenefitKey: 'scale-25-percent-benefit',
                icon: LucideIcons.circle,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'trigger-radar-usage-tips',
            items: [
              HelpItem(
                titleKey: 'focus-outer-rings',
                descriptionKey: 'trigger-radar-usage-tips-desc',
                recoveryBenefitKey: 'focus-outer-rings-benefit',
                icon: LucideIcons.target,
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'using-trigger-radar',
            items: [
              HelpItem(
                titleKey: 'track-trigger-changes',
                descriptionKey: 'track-trigger-changes-desc',
                recoveryBenefitKey: 'track-trigger-changes-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'develop-strategies',
                descriptionKey: 'develop-strategies-desc',
                recoveryBenefitKey: 'develop-strategies-benefit',
                icon: LucideIcons.shield,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showRiskClockHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'risk-clock-help-title',
        icon: LucideIcons.clock,
        iconColor: const Color(0xFF06B6D4),
        howToReadSections: [
          HelpSection(
            titleKey: 'risk-clock-overview',
            items: [
              HelpItem(
                titleKey: 'risk-clock-purpose',
                descriptionKey: 'risk-clock-purpose-desc',
                recoveryBenefitKey: 'risk-clock-purpose-benefit',
                icon: LucideIcons.clock,
                iconColor: const Color(0xFF06B6D4),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'risk-clock-interpretation',
            items: [
              HelpItem(
                titleKey: 'high-risk-hours',
                descriptionKey: 'high-risk-hours-desc',
                recoveryBenefitKey: 'high-risk-hours-benefit',
                icon: LucideIcons.alertTriangle,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'medium-risk-hours',
                descriptionKey: 'medium-risk-hours-desc',
                recoveryBenefitKey: 'medium-risk-hours-benefit',
                icon: LucideIcons.alertCircle,
                iconColor: const Color(0xFFF97316),
              ),
              HelpItem(
                titleKey: 'low-risk-hours',
                descriptionKey: 'low-risk-hours-desc',
                recoveryBenefitKey: 'low-risk-hours-benefit',
                icon: LucideIcons.shield,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'using-risk-clock',
            items: [
              HelpItem(
                titleKey: 'schedule-activities',
                descriptionKey: 'schedule-activities-desc',
                recoveryBenefitKey: 'schedule-activities-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF06B6D4),
              ),
              HelpItem(
                titleKey: 'set-reminders',
                descriptionKey: 'set-reminders-desc',
                recoveryBenefitKey: 'set-reminders-benefit',
                icon: LucideIcons.bell,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showMoodCorrelationHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'mood-correlation-help-title',
        icon: LucideIcons.heartHandshake,
        iconColor: const Color(0xFFEC4899),
        howToReadSections: [
          HelpSection(
            titleKey: 'mood-correlation-overview',
            items: [
              HelpItem(
                titleKey: 'mood-correlation-purpose',
                descriptionKey: 'mood-correlation-purpose-desc',
                recoveryBenefitKey: 'mood-correlation-purpose-benefit',
                icon: LucideIcons.heartHandshake,
                iconColor: const Color(0xFFEC4899),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'mood-correlation-interpretation',
            items: [
              HelpItem(
                titleKey: 'high-correlation',
                descriptionKey: 'high-correlation-desc',
                recoveryBenefitKey: 'high-correlation-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFFEF4444),
              ),
              HelpItem(
                titleKey: 'low-correlation',
                descriptionKey: 'low-correlation-desc',
                recoveryBenefitKey: 'low-correlation-benefit',
                icon: LucideIcons.trendingDown,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'mood-ranges',
                descriptionKey: 'mood-ranges-desc',
                recoveryBenefitKey: 'mood-ranges-benefit',
                icon: LucideIcons.barChart,
                iconColor: const Color(0xFFEC4899),
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'using-mood-correlation',
            items: [
              HelpItem(
                titleKey: 'identify-mood-triggers',
                descriptionKey: 'identify-mood-triggers-desc',
                recoveryBenefitKey: 'identify-mood-triggers-benefit',
                icon: LucideIcons.search,
                iconColor: const Color(0xFFEC4899),
              ),
              HelpItem(
                titleKey: 'mood-management',
                descriptionKey: 'mood-management-desc',
                recoveryBenefitKey: 'mood-management-benefit',
                icon: LucideIcons.heart,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showStreakAveragesHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => HelpBottomSheet(
        titleKey: 'streak-averages-help-title',
        icon: LucideIcons.trendingUp,
        iconColor: const Color(0xFF22C55E),
        howToReadSections: [
          HelpSection(
            titleKey: 'streak-averages-overview',
            items: [
              HelpItem(
                titleKey: 'streak-averages-purpose',
                descriptionKey: 'streak-averages-purpose-desc',
                recoveryBenefitKey: 'streak-averages-purpose-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFF22C55E),
              ),
            ],
          ),
          HelpSection(
            titleKey: 'streak-averages-metrics',
            items: [
              HelpItem(
                titleKey: 'overall-average',
                descriptionKey: 'overall-average-desc',
                recoveryBenefitKey: 'overall-average-benefit',
                icon: LucideIcons.barChart,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'recent-average',
                descriptionKey: 'recent-average-desc',
                recoveryBenefitKey: 'recent-average-benefit',
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF06B6D4),
              ),
              HelpItem(
                titleKey: 'improvement-trend',
                descriptionKey: 'improvement-trend-desc',
                recoveryBenefitKey: 'improvement-trend-benefit',
                icon: LucideIcons.trendingUp,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ],
        howToUseSections: [
          HelpSection(
            titleKey: 'using-streak-averages',
            items: [
              HelpItem(
                titleKey: 'track-progress',
                descriptionKey: 'track-progress-desc',
                recoveryBenefitKey: 'track-progress-benefit',
                icon: LucideIcons.target,
                iconColor: const Color(0xFF22C55E),
              ),
              HelpItem(
                titleKey: 'set-realistic-goals',
                descriptionKey: 'set-realistic-goals-desc',
                recoveryBenefitKey: 'set-realistic-goals-benefit',
                icon: LucideIcons.flag,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
