import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class QuickAccessWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.goNamed(RouteNames.activities.name);
            },
            child: WidgetsContainer(
              padding: EdgeInsets.all(12),
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[100]!, width: 1),
              boxShadow: Shadows.mainShadows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.clipboardCheck,
                    size: 18,
                    color: theme.primary[900],
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate("activities"),
                    style: TextStyles.footnote.copyWith(color: theme.grey[900]),
                  ),
                ],
              ),
            ),
          ),
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.goNamed(RouteNames.library.name);
            },
            child: WidgetsContainer(
              padding: EdgeInsets.all(12),
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[100]!, width: 1),
              boxShadow: Shadows.mainShadows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.lamp,
                    size: 18,
                    color: theme.primary[900],
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate("library"),
                    style: TextStyles.footnote.copyWith(color: theme.grey[900]),
                  ),
                ],
              ),
            ),
          ),
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.goNamed(RouteNames.diaries.name);
            },
            child: WidgetsContainer(
              padding: EdgeInsets.all(12),
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[100]!, width: 1),
              boxShadow: Shadows.mainShadows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: theme.primary[900],
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate("diaries"),
                    style: TextStyles.footnote.copyWith(color: theme.grey[900]),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
