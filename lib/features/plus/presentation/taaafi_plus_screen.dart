import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:figma_squircle/figma_squircle.dart';

class TaaafiPlusScreen extends ConsumerStatefulWidget {
  const TaaafiPlusScreen({super.key});

  @override
  ConsumerState<TaaafiPlusScreen> createState() => _TaaafiPlusScreenState();
}

class _TaaafiPlusScreenState extends ConsumerState<TaaafiPlusScreen> {
  bool isYearlySelected = true;

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
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 200),
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
                padding: EdgeInsets.all(20),
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
                    // Plan selection title
                    Text(
                      AppLocalizations.of(context)
                          .translate('select-plan-title'),
                      style: TextStyles.h6.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points16),
                    // Compact pricing plans
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactPlanCard(
                            context,
                            theme,
                            true,
                            AppLocalizations.of(context)
                                .translate('yearly-plan'),
                            AppLocalizations.of(context)
                                .translate('yearly-price'),
                            AppLocalizations.of(context)
                                .translate('yearly-period'),
                            AppLocalizations.of(context)
                                .translate('savings-percentage'),
                          ),
                        ),
                        horizontalSpace(Spacing.points12),
                        Expanded(
                          child: _buildCompactPlanCard(
                            context,
                            theme,
                            false,
                            AppLocalizations.of(context)
                                .translate('monthly-plan'),
                            AppLocalizations.of(context)
                                .translate('monthly-price'),
                            AppLocalizations.of(context)
                                .translate('monthly-period'),
                            null,
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points12),
                    // Cancel anytime text
                    Text(
                      AppLocalizations.of(context)
                          .translate('change-plans-anytime'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                    verticalSpace(Spacing.points16),
                    // CTA Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _startFreeTrial();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: ShapeDecoration(
                          color: theme.primary[600],
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 12,
                              cornerSmoothing: 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('start-free-trial'),
                            style: TextStyles.h6.copyWith(
                              color: theme.grey[50],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

  Widget _buildCompactPlanCard(
    BuildContext context,
    CustomThemeData theme,
    bool isRecommended,
    String planName,
    String price,
    String period,
    String? savings,
  ) {
    final bool isSelected = (isRecommended && isYearlySelected) ||
        (!isRecommended && !isYearlySelected);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          isYearlySelected = isRecommended;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: theme.backgroundColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              color: isSelected ? theme.primary[600]! : theme.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Plan name and selection indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planName,
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: theme.primary[600],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: theme.grey[50],
                      size: 12,
                    ),
                  ),
              ],
            ),
            if (savings != null) ...[
              verticalSpace(Spacing.points4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.success[100]!,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  savings,
                  style: TextStyles.footnote.copyWith(
                    color: theme.success[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            verticalSpace(Spacing.points8),
            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
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
              _buildFeatureRow(
                  context, theme, 'unlimited-activities', false, true),
              _buildFeatureRow(
                  context, theme, 'ad-free-experience', false, true),
              _buildFeatureRow(context, theme, 'barcode-scanning', false, true),
              _buildFeatureRow(
                  context, theme, 'custom-macro-tracking-feature', false, true),
              _buildFeatureRow(
                  context, theme, 'advanced-tracking', false, true),
              _buildFeatureRow(context, theme, 'custom-reminders', true, true),
              _buildFeatureRow(context, theme, 'priority-support', false, true),
              _buildFeatureRow(context, theme, 'export-data', false, true),
              _buildFeatureRow(context, theme, 'offline-access', false, true,
                  isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    dynamic theme,
    String featureKey,
    bool freeVersion,
    bool premiumVersion, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: theme.grey[200]!, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // Feature name
          Expanded(
            flex: 2,
            child: Text(
              AppLocalizations.of(context).translate(featureKey),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[800],
              ),
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
