import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:reboot_app_3/features/plus/presentation/feature_suggestion_modal.dart';

class PlusFeaturesGuideScreen extends ConsumerWidget {
  final bool fromPurchase;

  const PlusFeaturesGuideScreen({
    super.key,
    this.fromPurchase = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.grey[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).translate('plus-features-guide-title'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thank you message (if from purchase)
            if (fromPurchase) ...[
              _buildThankYouMessage(context, theme),
              verticalSpace(Spacing.points24),
            ],

            // Header section
            _buildHeader(context, theme),
            verticalSpace(Spacing.points32),

            // Features list
            _buildFeaturesList(context, theme),

            verticalSpace(Spacing.points32),

            // Support section
            _buildSupportSection(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEBA01).withValues(alpha: 0.1),
            const Color(0xFFFEBA01).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ta3afiPlatformIcons.plus_icon,
                color: const Color(0xFFFEBA01),
                size: 32,
              ),
              horizontalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context).translate('plus-features-welcome'),
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context)
                .translate('plus-features-welcome-desc'),
            textAlign: TextAlign.center,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Analytics
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.barChart3,
          iconColor: const Color(0xFF8B5CF6),
          title: AppLocalizations.of(context).translate('detailed-analytics'),
          description: AppLocalizations.of(context)
              .translate('plus-analytics-guide-desc'),
          onTap: () => context.pushNamed(RouteNames.premiumAnalytics.name),
        ),

        verticalSpace(Spacing.points16),

        // Smart Alerts
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.bell,
          iconColor: const Color(0xFF3B82F6),
          title:
              AppLocalizations.of(context).translate('smart-alerts-forecasts'),
          description: AppLocalizations.of(context)
              .translate('plus-smart-alerts-guide-desc'),
          onTap: () => context.pushNamed(RouteNames.smartAlertsSettings.name),
        ),

        verticalSpace(Spacing.points16),

        // Community Perks
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.award,
          iconColor: const Color(0xFFF59E0B),
          title: AppLocalizations.of(context).translate('community-perks'),
          description: AppLocalizations.of(context)
              .translate('plus-community-perks-guide-desc'),
          onTap: () => context.pushNamed(RouteNames.community.name),
        ),

        verticalSpace(Spacing.points16),

        // Custom Reminders
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.bell,
          iconColor: const Color(0xFF10B981),
          title: AppLocalizations.of(context).translate('custom-reminders'),
          description: AppLocalizations.of(context)
              .translate('plus-custom-reminders-guide-desc'),
          onTap: () => _showRemindersInfo(context),
        ),

        verticalSpace(Spacing.points16),

        // Priority Support
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.headphones,
          iconColor: const Color(0xFFEF4444),
          title: AppLocalizations.of(context).translate('priority-support'),
          description: AppLocalizations.of(context)
              .translate('plus-priority-support-guide-desc'),
          onTap: () => _contactSupport(context),
        ),

        verticalSpace(Spacing.points16),

        // Feature Suggestions
        _buildFeatureCard(
          context,
          theme,
          icon: LucideIcons.lightbulb,
          iconColor: const Color(0xFF8B5CF6),
          title: AppLocalizations.of(context).translate('suggest-feature'),
          description: AppLocalizations.of(context)
              .translate('feature-suggestion-guide-desc'),
          onTap: () => _showFeatureSuggestionModal(context),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    dynamic theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.grey[300]!.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            WidgetsContainer(
              padding: const EdgeInsets.all(12),
              backgroundColor: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
            horizontalSpace(Spacing.points16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    description,
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!isArabic)
              Icon(
                LucideIcons.chevronRight,
                color: theme.grey[400],
                size: 20,
              ),
            if (isArabic)
              Icon(
                LucideIcons.chevronLeft,
                color: theme.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            AppLocalizations.of(context).translate('plus-support-message'),
            textAlign: TextAlign.center,
            style: TextStyles.footnote.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () => _contactSupport(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: ShapeDecoration(
                color: theme.primary[600],
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 8,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .translate('contact-support-button'),
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[50],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemindersInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('custom-reminders')),
        content: Text(
            AppLocalizations.of(context).translate('reminders-info-dialog')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('got-it')),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouMessage(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.success[600]!.withValues(alpha: 0.1),
            theme.success[600]!.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.success[600]!.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.success[600],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.check,
              color: Colors.white,
              size: 32,
            ),
          ),
          verticalSpace(Spacing.points16),

          // Thank you title
          Text(
            AppLocalizations.of(context).translate('purchase-thank-you-title'),
            style: TextStyles.h4.copyWith(
              color: theme.success[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points8),

          // Thank you message
          Text(
            AppLocalizations.of(context)
                .translate('purchase-thank-you-message'),
            style: TextStyles.body.copyWith(
              color: theme.success[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points16),

          // Explore features button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Scroll to features section (or any other action)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .translate('explore-features-hint')),
                  backgroundColor: theme.success[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: ShapeDecoration(
                color: theme.success[600],
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 8,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context)
                        .translate('explore-features-button'),
                    style: TextStyles.footnote.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('priority-support')),
        content: Text(
            AppLocalizations.of(context).translate('support-contact-dialog')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('got-it')),
          ),
        ],
      ),
    );
  }

  void _showFeatureSuggestionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeatureSuggestionModal(),
    );
  }
}
