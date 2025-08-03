import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('subscription-main-title'),
                            style: TextStyles.h1.copyWith(
                              color: const Color(0xFFFEBA01),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points16),
                        Icon(
                          Ta3afiPlatformIcons.plus_icon,
                          color: const Color(0xFFFEBA01),
                          size: 60,
                        ),
                      ],
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
                    // Dynamic pricing from RevenueCat
                    Consumer(
                      builder: (context, ref, _) {
                        final packagesAsync =
                            ref.watch(availablePackagesProvider);

                        return packagesAsync.when(
                            data: (packages) => _buildPackageOptions(
                                context, theme, packages, ref),
                            loading: () =>
                                _buildLoadingPurchaseButton(context, theme),
                            error: (error, _) {
                              print('error: $error');
                              return _buildFallbackPurchaseButton(
                                  context, theme, ref);
                            });
                      },
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
              _buildPersonalAnalyticsFeatureRow(context, theme, false, true),
              _buildCommunityPerksFeatureRow(context, theme, false, true),
              _buildSmartAlertsFeatureRow(context, theme, false, true),
              _buildFeatureRowWithIcon(context, theme, 'custom-reminders',
                  LucideIcons.bell, Color(0xFF3B82F6), true, true),
              _buildFeatureRowWithIcon(context, theme, 'priority-support',
                  LucideIcons.headphones, Color(0xFF10B981), false, true),
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

  Widget _buildPersonalAnalyticsFeatureRow(
    BuildContext context,
    dynamic theme,
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
          // Personal Analytics insights (only show for premium)
          if (premiumVersion) ...[
            verticalSpace(Spacing.points12),
            Padding(
              padding: EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _buildInsightItem(context, theme, LucideIcons.calendar,
                      'heat-map-calendar', Color(0xFFEF4444)),
                  _buildInsightItem(context, theme, LucideIcons.radar,
                      'trigger-radar', Color(0xFFF97316)),
                  _buildInsightItem(context, theme, LucideIcons.clock,
                      'risk-clock', Color(0xFF06B6D4)),
                  _buildInsightItem(context, theme, LucideIcons.heartHandshake,
                      'mood-relapse-correlation', Color(0xFFEC4899),
                      isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommunityPerksFeatureRow(
    BuildContext context,
    dynamic theme,
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
                          LucideIcons.award,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('community-perks'),
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
                            .translate('community-perks-desc'),
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
          // Community Perks insights (only show for premium)
          if (premiumVersion) ...[
            verticalSpace(Spacing.points12),
            Padding(
              padding: EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _buildInsightItem(context, theme, LucideIcons.crown,
                      'plus-badge-flair', Color(0xFFF59E0B)),
                  _buildInsightItem(context, theme, LucideIcons.trendingUp,
                      'featured-post-boost', Color(0xFF10B981)),
                  _buildInsightItem(context, theme, LucideIcons.user,
                      'streak-overlay-avatar', Color(0xFF3B82F6),
                      isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartAlertsFeatureRow(
    BuildContext context,
    dynamic theme,
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
                          LucideIcons.bell,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('smart-alerts-forecasts'),
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
                            .translate('smart-alerts-forecasts-desc'),
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
          // Smart Alerts insights (only show for premium)
          if (premiumVersion) ...[
            verticalSpace(Spacing.points12),
            Padding(
              padding: EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _buildInsightItem(context, theme, LucideIcons.alertTriangle,
                      'high-risk-hour-alert', Color(0xFFEF4444)),
                  _buildInsightItem(context, theme, LucideIcons.shield,
                      'streak-vulnerability-alert', Color(0xFF8B5CF6)),
                  _buildInsightItem(context, theme, LucideIcons.messageSquare,
                      'topic-based-pushes', Color(0xFF06B6D4),
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

  /// Build package options with real pricing from RevenueCat
  Widget _buildPackageOptions(BuildContext context, dynamic theme,
      List<Package> packages, WidgetRef ref) {
    if (packages.isEmpty) {
      return _buildFallbackPurchaseButton(context, theme, ref);
    }

    // For now, show the first package (you can enhance this to show multiple)
    final package = packages.first;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _purchasePackage(package);
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
              '${package.storeProduct.priceString}/${_getPackagePeriod(package)}',
              style: TextStyles.footnote.copyWith(
                color: theme.grey[50],
                fontWeight: FontWeight.bold,
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              package.storeProduct.introductoryPrice?.price != null
                  ? AppLocalizations.of(context).translate('start-free-trial')
                  : AppLocalizations.of(context).translate('subscribe-now'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[50],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading state for purchase button
  Widget _buildLoadingPurchaseButton(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: theme.grey[400],
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 8,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: theme.grey[50],
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// Build fallback purchase button when packages fail to load
  Widget _buildFallbackPurchaseButton(
      BuildContext context, dynamic theme, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await ref
            .read(urlLauncherProvider)
            .launch(Uri.parse('https://wa.me/96876691799'));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: theme.error[50],
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)
                  .translate('there-is-something-worng-contact-us'),
              style: TextStyles.footnote.copyWith(
                color: theme.error[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purchase a specific package
  void _purchasePackage(Package package) async {
    try {
      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      final success = await notifier.purchasePackage(package);

      if (success) {
        // Close the paywall first
        Navigator.of(context).pop();

        // Navigate to Plus Features Guide with success flag
        context.pushNamed(RouteNames.plusFeaturesGuide.name,
            extra: {'fromPurchase': true});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('purchase-failed')),
          backgroundColor: AppTheme.of(context).error[600],
        ),
      );
    }
  }

  /// Get package period for display
  String _getPackagePeriod(Package package) {
    final packageType = package.packageType;
    switch (packageType) {
      case PackageType.monthly:
        return AppLocalizations.of(context).translate('month');
      case PackageType.annual:
        return AppLocalizations.of(context).translate('year');
      case PackageType.weekly:
        return AppLocalizations.of(context).translate('week');
      default:
        return AppLocalizations.of(context).translate('month');
    }
  }
}
