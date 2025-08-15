import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

class PremiumBlurOverlay extends StatelessWidget {
  final Widget content;
  final bool isDarkTheme;
  final BoxConstraints? constraints;
  final EdgeInsets? margin;
  final String? customTitle;
  final String? customSubtitle;

  const PremiumBlurOverlay({
    super.key,
    required this.content,
    required this.isDarkTheme,
    this.constraints,
    this.margin,
    this.customTitle,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (context) => const TaaafiPlusSubscriptionScreen(),
        );
      },
      child: Container(
        constraints: constraints ??
            const BoxConstraints(
              minHeight: 120,
              maxHeight: 280,
            ),
        margin: margin ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Original content (visible through blur)
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: content,
              ),
            ),

            // Progressive blur overlay with smooth corners
            Positioned.fill(
              child: ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: 20,
                  cornerSmoothing: 0.9,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      // Theme-aware progressive gradient overlay
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkTheme
                            ? [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.65),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.85),
                                Colors.white.withValues(alpha: 0.65),
                              ],
                        stops: const [0.0, 0.25, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Premium upgrade overlay
            Positioned.fill(
              child: Center(
                child: _buildUpgradePrompt(context, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context, CustomThemeData theme) {
    // Unified color scheme for premium features
    final iconColor = theme.primary[50]!;
    final titleColor = isDarkTheme ? theme.grey[100]! : theme.grey[900]!;
    final subtitleColor = isDarkTheme ? theme.grey[700]! : theme.grey[900]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Unified premium icon with consistent styling
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: theme.primary[100]!,
              width: 0.2,
            ),
            boxShadow: Shadows.mainShadows,
          ),
          child: Icon(
            Ta3afiPlatformIcons.plus_icon, // Using custom plus icon
            color: const Color(0xFFFEBA01),
            size: 24,
          ),
        ),

        verticalSpace(Spacing.points16),

        // Unified title text
        Text(
          customTitle ??
              AppLocalizations.of(context).translate('upgrade-to-plus'),
          style: TextStyles.body.copyWith(
            color: const Color(0xFFFEBA01),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),

        verticalSpace(Spacing.points8),

        // Unified subtitle text
        Text(
          customSubtitle ??
              AppLocalizations.of(context)
                  .translate('unlock-premium-analytics'),
          style: TextStyles.footnote.copyWith(
            color: subtitleColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
