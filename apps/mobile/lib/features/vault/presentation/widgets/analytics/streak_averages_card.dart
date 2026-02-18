import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/follow_up_history_modal.dart';

class StreakAveragesCard extends ConsumerWidget {
  const StreakAveragesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final streakAveragesAsync = ref.watch(streakAveragesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak averages content
        streakAveragesAsync.when(
          data: (averages) =>
              _buildStreakAverages(context, theme, averages, ref),
          loading: () => Center(child: Spinner()),
          error: (_, __) => _buildEmptyState(context, theme),
        ),
      ],
    );
  }

  Widget _buildStreakAverages(BuildContext context, dynamic theme,
      Map<String, double> averages, WidgetRef ref) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildAverageCard(
                  context,
                  theme,
                  ref,
                  '7-day-average',
                  '${averages['7days']?.toInt() ?? 0}%',
                  7,
                  Color(0xFF22C55E),
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: _buildAverageCard(
                  context,
                  theme,
                  ref,
                  '30-day-average',
                  '${averages['30days']?.toInt() ?? 0}%',
                  30,
                  Color(0xFF3B82F6),
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: _buildAverageCard(
                  context,
                  theme,
                  ref,
                  '90-day-average',
                  '${averages['90days']?.toInt() ?? 0}%',
                  90,
                  Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAverageCard(BuildContext context, dynamic theme, WidgetRef ref,
      String titleKey, String value, int days, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFollowUpHistoryModal(context, ref, days: days);
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(12),
        backgroundColor: theme.backgroundColor,
        borderSide:
            BorderSide(color: accentColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyles.h4.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate(titleKey),
              style: TextStyles.small.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            verticalSpace(Spacing.points12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context).translate('tap-to-view'),
                style: TextStyles.small.copyWith(
                  color: accentColor,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.trendingUp,
            color: theme.grey[400],
            size: 32,
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate('streak-averages-empty'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFollowUpHistoryModal(BuildContext context, WidgetRef ref,
      {int? days}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => FollowUpHistoryModal(
        days: days,
      ),
    );
  }
}
