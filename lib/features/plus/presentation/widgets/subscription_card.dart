import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_screen.dart';

class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (BuildContext context) {
            return const TaaafiPlusScreen();
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(1.00, 0.00),
            end: Alignment(-0.02, 1.06),
            colors: [Color(0xFF588689), Color(0xFF326367)],
          ),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.crown,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('ta3afi-plus'),
                    style: TextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            verticalSpace(Spacing.points16),

            // Catchy headline
            Text(
              AppLocalizations.of(context)
                  .translate('start-every-day-with-great-ideas'),
              style: TextStyles.h6.copyWith(
                color: Colors.white,
                height: 1.3,
              ),
            ),

            verticalSpace(Spacing.points8),

            // Description
            Text(
              AppLocalizations.of(context).translate('plus-description'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),

            verticalSpace(Spacing.points20),

            // Subscribe button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .translate('upgrade-now')
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyles.footnoteSelected.copyWith(
                  color: const Color(0xFF326367),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
