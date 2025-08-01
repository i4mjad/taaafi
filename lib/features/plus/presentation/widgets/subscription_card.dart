import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (hasActiveSubscription) {
          // Navigate to Plus Features Guide for existing Plus users
          context.pushNamed(RouteNames.plusFeaturesGuide.name);
        } else {
          // Show subscription screen for non-Plus users
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (BuildContext context) {
              return const TaaafiPlusSubscriptionScreen();
            },
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: theme.backgroundColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 24,
              cornerSmoothing: 1,
            ),
          ),
          shadows: Shadows.mainShadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature icons row
              _buildFeatureIconsRow(theme),

              verticalSpace(Spacing.points16),

              // Title with Plus icon
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    hasActiveSubscription
                        ? AppLocalizations.of(context)
                            .translate('plus-features-welcome')
                        : AppLocalizations.of(context).translate('plus'),
                    style: TextStyles.h5.copyWith(
                      color: const Color(0xFFFEBA01),
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),

              verticalSpace(Spacing.points8),

              // Description
              Text(
                hasActiveSubscription
                    ? AppLocalizations.of(context)
                        .translate('plus-features-welcome-desc')
                    : AppLocalizations.of(context)
                        .translate('free-trial-description'),
                textAlign: TextAlign.start,
                style: TextStyles.body.copyWith(
                  color: const Color(0xFF95A1AC),
                  height: 1.4,
                  fontSize: 16,
                ),
              ),

              verticalSpace(Spacing.points12),

              // Action button - smaller and left-aligned
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFEBA01),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 12,
                      cornerSmoothing: 1,
                    ),
                  ),
                ),
                width: double.infinity,
                child: Center(
                  child: Text(
                    hasActiveSubscription
                        ? AppLocalizations.of(context)
                            .translate('explore-features-button')
                        : AppLocalizations.of(context)
                            .translate('subscribe-now'),
                    style: TextStyles.caption.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIconsRow(dynamic theme) {
    // More feature icons representing Plus features (smaller and more icons)
    final List<IconData> featureIcons = [
      LucideIcons.video, // Video/camera features
      LucideIcons.fileSpreadsheet, // Analytics/reports
      LucideIcons.trendingUp, // Growth/progress
      LucideIcons.barChart3, // Charts/analytics
      LucideIcons.pieChart, // Pie charts
      LucideIcons.activity, // Activity tracking
      LucideIcons.calendar, // Calendar features
      LucideIcons.target, // Goals/targets
      LucideIcons.heart, // Health/wellness
      LucideIcons.users, // Community
      LucideIcons.bell, // Notifications
      LucideIcons.zap, // Energy/power
      LucideIcons.award, // Achievements
      LucideIcons.trendingUp, // Trends
      LucideIcons.shield, // Protection/security
    ];

    final List<Color> iconColors = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFFEBA01), // Yellow
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Green
    ];

    return SizedBox(
      height: 24,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1000, // Infinite scrolling
        itemBuilder: (context, index) {
          final iconIndex = index % featureIcons.length;
          final colorIndex = index % iconColors.length;
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 24,
            height: 24,
            decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 6,
                  cornerSmoothing: 1,
                ),
              ),
              color: iconColors[colorIndex].withValues(alpha: 0.15),
            ),
            child: Icon(
              featureIcons[iconIndex],
              color: iconColors[colorIndex],
              size: 12,
            ),
          );
        },
      ),
    );
  }
}
