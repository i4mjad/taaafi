import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class VaultInfoBottomSheet extends StatelessWidget {
  const VaultInfoBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              LucideIcons.badgeInfo,
              color: theme.primary[900],
              size: 72,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context).translate("vault-features"),
              style: TextStyles.h5.copyWith(color: theme.grey[900]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureSection(
                      context,
                      theme,
                      LucideIcons.clipboardCheck,
                      "activities",
                      "activities-description",
                    ),
                    verticalSpace(Spacing.points24),
                    _buildFeatureSection(
                      context,
                      theme,
                      LucideIcons.lamp,
                      "library",
                      "library-description",
                    ),
                    verticalSpace(Spacing.points24),
                    _buildFeatureSection(
                      context,
                      theme,
                      LucideIcons.pencil,
                      "diaries",
                      "diaries-description",
                    ),
                    verticalSpace(Spacing.points24),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[500],
                  foregroundColor: theme.grey[50],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 8,
                      cornerSmoothing: 1,
                    ),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).translate("close"),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[50],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context,
    CustomThemeData theme,
    IconData icon,
    String titleKey,
    String descriptionKey,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsContainer(
          padding: const EdgeInsets.all(12),
          backgroundColor: theme.primary[50],
          borderSide: BorderSide(color: theme.primary[100]!),
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            size: 24,
            color: theme.primary[900],
          ),
        ),
        horizontalSpace(Spacing.points16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate(titleKey),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              verticalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context).translate(descriptionKey),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
