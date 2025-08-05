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
import 'package:reboot_app_3/features/vault/presentation/widgets/follow_up/follow_up_sheet.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    final actions = [
      _QuickAction(
        icon: LucideIcons.plus,
        label: localization.translate("follow-up"),
        color: theme.primary[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return FollowUpSheet(DateTime.now());
            },
          );
        },
      ),
      _QuickAction(
        icon: LucideIcons.book,
        label: localization.translate("add-diary-entry"),
        color: theme.success[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.diaries.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.library,
        label: localization.translate("explore-content"),
        color: theme.tint[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.library.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.pieChart,
        label: localization.translate("statistics"),
        color: theme.warn[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.goNamed(RouteNames.vault.name);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            localization.translate("quick-access"),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
        ),
        verticalSpace(Spacing.points12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: QuickActionButton(action: actions[0])),
                  horizontalSpace(Spacing.points8),
                  Expanded(child: QuickActionButton(action: actions[1])),
                ],
              ),
              verticalSpace(Spacing.points8),
              Row(
                children: [
                  Expanded(child: QuickActionButton(action: actions[2])),
                  horizontalSpace(Spacing.points8),
                  Expanded(child: QuickActionButton(action: actions[3])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class QuickActionButton extends ConsumerWidget {
  final _QuickAction action;

  const QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: action.onTap,
      child: WidgetsContainer(
        padding: const EdgeInsets.all(8),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[400]!, width: 0.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: Shadows.mainShadows,
        child: Row(
          children: [
            Icon(action.icon, color: action.color),
            horizontalSpace(Spacing.points8),
            Text(action.label,
                style: TextStyles.small.copyWith(color: theme.grey[900])),
          ],
        ),
      ),
    );
  }
}
