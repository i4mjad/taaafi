import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:figma_squircle/figma_squircle.dart';

class TaaafiPlusSubscriptionScreen extends ConsumerStatefulWidget {
  const TaaafiPlusSubscriptionScreen({super.key});

  @override
  ConsumerState<TaaafiPlusSubscriptionScreen> createState() =>
      _TaaafiPlusScreenState();
}

class _TaaafiPlusScreenState
    extends ConsumerState<TaaafiPlusSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.95,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Modal handle
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(Spacing.points24),
                    // Main title
                    Text(
                      AppLocalizations.of(context)
                          .translate('subscription-main-title'),
                      style: TextStyles.h1.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    verticalSpace(Spacing.points16),
                    // Subtitle
                    Text(
                      AppLocalizations.of(context)
                          .translate('subscription-subtitle'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[700],
                        height: 1.5,
                      ),
                    ),
                    verticalSpace(Spacing.points32),
                    // Features comparison table
                    _buildFeaturesComparisonTable(context, theme),

                    verticalSpace(Spacing.points80),
                  ],
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.grey[500]?.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    color: theme.grey[700],
                    size: 24,
                  ),
                ),
              ),
            ),
            // Bottom section with pricing and CTA
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: theme.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Combined pricing and CTA button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _startFreeTrial();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: theme.primary[600],
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 8,
                              cornerSmoothing: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('subscription-monthly-price'),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[50],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            verticalSpace(Spacing.points4),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('start-free-trial'),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[50],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    verticalSpace(Spacing.points8),
                    // Cancel anytime text
                    Text(
                      AppLocalizations.of(context)
                          .translate('change-plans-anytime'),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparisonTable(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table title
        Text(
          AppLocalizations.of(context).translate('what-you-get'),
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points20),

        // Table header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.grey[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Container()), // Feature name column
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('free-version'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('premium-version'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Features list
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.grey[200]!, width: 1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              _buildAnalyticsFeatureRow(context, theme, false, true),
              _buildFeatureRowWithIcon(context, theme, 'custom-reminders',
                  LucideIcons.bell, Color(0xFF3B82F6), true, true),
              _buildFeatureRowWithIcon(context, theme, 'priority-support',
                  LucideIcons.headphones, Color(0xFF10B981), false, true),
              _buildFeatureRowWithIcon(
                  context,
                  theme,
                  'special-community-badge',
                  LucideIcons.award,
                  Color(0xFFF59E0B),
                  false,
                  true),
              _buildFeatureRowWithIcon(context, theme, 'feature-requests',
                  LucideIcons.lightbulb, Color(0xFFEAB308), false, true,
                  isLast: true),
            ],
          ),
        ),

        verticalSpace(Spacing.points24),

        // Working hard message
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.heart,
                color: theme.primary[600],
                size: 32,
              ),
              verticalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context).translate('working-hard-message'),
                textAlign: TextAlign.center,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsFeatureRow(
    BuildContext context,
    dynamic theme,
    bool freeVersion,
    bool premiumVersion, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.grey[200]!, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Main feature row
          Row(
            children: [
              // Feature name with icon
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.barChart3,
                          color: Color(0xFF8B5CF6),
                          size: 18,
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('detailed-analytics'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points4),
                    Padding(
                      padding: EdgeInsets.only(left: 26),
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('detailed-analytics-desc'),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Free version
              Expanded(
                flex: 1,
                child: Center(
                  child: freeVersion
                      ? Icon(
                          LucideIcons.check,
                          color: theme.success[600],
                          size: 18,
                        )
                      : Icon(
                          LucideIcons.x,
                          color: theme.grey[400],
                          size: 18,
                        ),
                ),
              ),
              // Premium version
              Expanded(
                flex: 1,
                child: Center(
                  child: premiumVersion
                      ? Icon(
                          LucideIcons.check,
                          color: theme.success[600],
                          size: 18,
                        )
                      : Icon(
                          LucideIcons.x,
                          color: theme.grey[400],
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
          // Analytics insights (only show for premium)
          if (premiumVersion) ...[
            verticalSpace(Spacing.points12),
            Padding(
              padding: EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _buildInsightItem(context, theme, LucideIcons.zap,
                      'streak-insights', Color(0xFFEF4444)),
                  _buildInsightItem(context, theme, LucideIcons.heart,
                      'mood-patterns', Color(0xFFEC4899)),
                  _buildInsightItem(context, theme, LucideIcons.alertTriangle,
                      'trigger-analysis', Color(0xFFF97316)),
                  _buildInsightItem(context, theme, LucideIcons.trendingUp,
                      'progress-trends', Color(0xFF06B6D4)),
                  _buildInsightItem(context, theme, LucideIcons.gitBranch,
                      'habit-correlation', Color(0xFF8B5CF6),
                      isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    dynamic theme,
    IconData icon,
    String textKey,
    Color iconColor, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 14,
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyles.small.copyWith(
                color: theme.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRowWithIcon(
    BuildContext context,
    dynamic theme,
    String featureKey,
    IconData icon,
    Color iconColor,
    bool freeVersion,
    bool premiumVersion, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: theme.grey[200]!, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // Feature name with icon and description
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 18,
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).translate(featureKey),
                        style: TextStyles.footnote.copyWith(
                          color: theme.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points4),
                Padding(
                  padding: EdgeInsets.only(left: 26),
                  child: Text(
                    AppLocalizations.of(context).translate('$featureKey-desc'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Free version
          Expanded(
            flex: 1,
            child: Center(
              child: freeVersion
                  ? Icon(
                      LucideIcons.check,
                      color: theme.success[600],
                      size: 18,
                    )
                  : Icon(
                      LucideIcons.x,
                      color: theme.grey[400],
                      size: 18,
                    ),
            ),
          ),
          // Premium version
          Expanded(
            flex: 1,
            child: Center(
              child: premiumVersion
                  ? Icon(
                      LucideIcons.check,
                      color: theme.success[600],
                      size: 18,
                    )
                  : Icon(
                      LucideIcons.x,
                      color: theme.grey[400],
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _startFreeTrial() {
    // TODO: Implement trial start logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context).translate('free-trial-started')),
        backgroundColor: AppTheme.of(context).primary[600],
      ),
    );
  }
}
