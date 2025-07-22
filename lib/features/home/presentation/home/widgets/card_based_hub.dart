import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/quick_actions_card.dart';

class CardBasedHub extends ConsumerWidget {
  const CardBasedHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle section - visually connected to app bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[200]!.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              localization.translate("dashboard-subtitle"),
              style: TextStyles.caption.copyWith(
                color: theme.grey[500],
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions Card (Implemented)
                QuickActionsCard(),
                verticalSpace(Spacing.points24),

                // Placeholder for next cards
                Text(
                  localization.translate("more-cards-coming-soon"),
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                // Future cards will be added here:
                // CurrentStreaksCard(),
                // ProgressOverviewCard(),
                // CalendarCard(),
                // CommunityInsightsCard(),
                // PersonalInsightsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
