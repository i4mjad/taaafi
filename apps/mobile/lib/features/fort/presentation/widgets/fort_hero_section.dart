import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/fort/domain/models/fort_state.dart';

class FortHeroSection extends StatelessWidget {
  final FortState? fortState;
  final bool isLoading;

  const FortHeroSection({super.key, required this.fortState})
      : isLoading = false;

  const FortHeroSection.loading({super.key})
      : fortState = null,
        isLoading = true;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  theme.primary[800]!.withValues(alpha: 0.3),
                  theme.grey[900]!,
                ]
              : [
                  theme.primary[50]!,
                  theme.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? theme.primary[700]!.withValues(alpha: 0.3)
              : theme.primary[100]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fort placeholder illustration
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.grey[800]!.withValues(alpha: 0.5)
                  : theme.grey[100]!,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator(
                      color: theme.primary[500],
                      strokeWidth: 2,
                    )
                  : Icon(
                      Icons.castle_rounded,
                      size: 64,
                      color: isDark ? theme.primary[300] : theme.primary[600],
                    ),
            ),
          ),

          verticalSpace(Spacing.points16),

          if (!isLoading && fortState != null) ...[
            // Fort level
            Text(
              '${t.translate('fort_level')} ${fortState!.level}',
              style: TextStyles.h3.copyWith(
                color: isDark ? theme.grey[100] : theme.grey[900],
                fontSize: 22,
              ),
            ),

            verticalSpace(Spacing.points8),

            // XP progress bar
            _buildXpBar(context, theme, isDark),

            verticalSpace(Spacing.points4),

            // XP text
            Text(
              '${fortState!.xp} / ${fortState!.xpForNextLevel} XP',
              style: TextStyles.footnote.copyWith(
                color: isDark ? theme.grey[400] : theme.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXpBar(
    BuildContext context,
    dynamic theme,
    bool isDark,
  ) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? theme.grey[700] : theme.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: fortState?.levelProgress ?? 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary[400]!,
                theme.primary[600]!,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
