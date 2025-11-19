import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/providers/clean_ban_warning_providers.dart';

/// A compact banner that shows when user has warnings and navigates to profile screen when tapped
class WarningNotificationBanner extends ConsumerWidget {
  const WarningNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final warningSummaryAsync = ref.watch(currentUserWarningSummaryProvider);

    return warningSummaryAsync.when(
      data: (summary) {
        // Don't show banner if no warnings
        if (summary.totalWarnings == 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pushNamed(RouteNames.userProfile.name);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.warn[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.warn[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.warn[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    size: 16,
                    color: theme.warn[700],
                  ),
                ),
                horizontalSpace(Spacing.points8),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.totalWarnings == 1
                            ? AppLocalizations.of(context)
                                .translate('you-have-warning')
                            : AppLocalizations.of(context)
                                .translate('you-have-warnings')
                                .replaceAll('{count}',
                                    summary.totalWarnings.toString()),
                        style: TextStyles.caption.copyWith(
                          color: theme.warn[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.warn[700],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
