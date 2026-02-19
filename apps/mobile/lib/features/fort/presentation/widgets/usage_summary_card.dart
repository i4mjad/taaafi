import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';

class UsageSummaryCard extends StatelessWidget {
  final UsageSummary? summary;
  final bool isLoading;

  const UsageSummaryCard({super.key, required this.summary})
      : isLoading = false;

  const UsageSummaryCard.loading({super.key})
      : summary = null,
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
        color: isDark ? theme.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? theme.grey[700]! : theme.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: isDark ? theme.primary[300] : theme.primary[600],
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('screen_time_today'),
                style: TextStyles.body.copyWith(
                  color: isDark ? theme.grey[100] : theme.grey[900],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          if (isLoading)
            _buildLoadingState(theme, isDark)
          else if (summary == null || summary!.categories.isEmpty)
            _buildEmptyState(context, theme, isDark, t)
          else ...[
            // Total screen time + pickups row
            _buildTotalRow(context, theme, isDark, t),

            verticalSpace(Spacing.points16),

            // Category bars
            ...summary!.categories.map(
              (cat) => _buildCategoryBar(context, cat, theme, isDark, t),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    dynamic theme,
    bool isDark,
    AppLocalizations t,
  ) {
    final hours = summary!.totalScreenTimeMinutes ~/ 60;
    final minutes = summary!.totalScreenTimeMinutes % 60;
    final timeStr = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';

    return Row(
      children: [
        // Total screen time
        Expanded(
          child: _buildStatBox(
            theme,
            isDark,
            icon: Icons.phone_android_rounded,
            value: timeStr,
            label: t.translate('total_screen_time'),
          ),
        ),
        const SizedBox(width: 12),
        // Pickups
        Expanded(
          child: _buildStatBox(
            theme,
            isDark,
            icon: Icons.touch_app_rounded,
            value: '${summary!.pickups}',
            label: t.translate('pickups'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(
    dynamic theme,
    bool isDark, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.grey[800]!.withValues(alpha: 0.5)
            : theme.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isDark ? theme.grey[400] : theme.grey[600]),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.body.copyWith(
              color: isDark ? theme.grey[100] : theme.grey[900],
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyles.footnote.copyWith(
              color: isDark ? theme.grey[400] : theme.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    UsageCategory category,
    dynamic theme,
    bool isDark,
    AppLocalizations t,
  ) {
    final maxMinutes = summary!.categories.isNotEmpty
        ? summary!.categories.first.minutes
        : 1;
    final fraction =
        maxMinutes > 0 ? (category.minutes / maxMinutes).clamp(0.0, 1.0) : 0.0;

    final hours = category.minutes ~/ 60;
    final minutes = category.minutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _categoryIcon(category.type),
                    size: 16,
                    color: _categoryColor(category.type),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.translate(category.type.translationKey),
                    style: TextStyles.footnote.copyWith(
                      color: isDark ? theme.grey[200] : theme.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                timeStr,
                style: TextStyles.footnote.copyWith(
                  color: isDark ? theme.grey[300] : theme.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? theme.grey[700] : theme.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: _categoryColor(category.type),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    dynamic theme,
    bool isDark,
    AppLocalizations t,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: isDark ? theme.grey[600] : theme.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('no_app_usage_data'),
              style: TextStyles.body.copyWith(
                color: isDark ? theme.grey[400] : theme.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(dynamic theme, bool isDark) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  static IconData _categoryIcon(UsageCategoryType type) {
    switch (type) {
      case UsageCategoryType.socialMedia:
        return Icons.people_rounded;
      case UsageCategoryType.entertainment:
        return Icons.movie_rounded;
      case UsageCategoryType.games:
        return Icons.sports_esports_rounded;
      case UsageCategoryType.productivity:
        return Icons.work_rounded;
      case UsageCategoryType.communication:
        return Icons.chat_rounded;
      case UsageCategoryType.education:
        return Icons.school_rounded;
      case UsageCategoryType.health:
        return Icons.favorite_rounded;
      case UsageCategoryType.news:
        return Icons.newspaper_rounded;
      case UsageCategoryType.other:
        return Icons.apps_rounded;
    }
  }

  static Color _categoryColor(UsageCategoryType type) {
    switch (type) {
      case UsageCategoryType.socialMedia:
        return const Color(0xFFE91E63);
      case UsageCategoryType.entertainment:
        return const Color(0xFFFF5722);
      case UsageCategoryType.games:
        return const Color(0xFF9C27B0);
      case UsageCategoryType.productivity:
        return const Color(0xFF2196F3);
      case UsageCategoryType.communication:
        return const Color(0xFF4CAF50);
      case UsageCategoryType.education:
        return const Color(0xFF00BCD4);
      case UsageCategoryType.health:
        return const Color(0xFFF44336);
      case UsageCategoryType.news:
        return const Color(0xFF607D8B);
      case UsageCategoryType.other:
        return const Color(0xFF9E9E9E);
    }
  }
}
