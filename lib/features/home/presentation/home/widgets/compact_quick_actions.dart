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
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';

class CompactQuickActions extends ConsumerWidget {
  const CompactQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    final actions = [
      _CompactAction(
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
      _CompactAction(
        icon: LucideIcons.book,
        label: localization.translate("add-diary-entry"),
        color: theme.success[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.diaries.name);
        },
      ),
      _CompactAction(
        icon: LucideIcons.library,
        label: localization.translate("explore-content"),
        color: theme.tint[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.library.name);
        },
      ),
      _CompactAction(
        icon: LucideIcons.pieChart,
        label: localization.translate("statistics"),
        color: theme.warn[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          //TODO: Add statistics screen (this is only for premium users)
          // TODO: Navigate to statistics screen
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
                  Expanded(child: CompactActionButton(action: actions[0])),
                  horizontalSpace(Spacing.points8),
                  Expanded(child: CompactActionButton(action: actions[1])),
                ],
              ),
              verticalSpace(Spacing.points8),
              Row(
                children: [
                  Expanded(child: CompactActionButton(action: actions[2])),
                  horizontalSpace(Spacing.points8),
                  Expanded(child: CompactActionButton(action: actions[3])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CompactAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class CompactActionButton extends ConsumerWidget {
  final _CompactAction action;

  const CompactActionButton({required this.action});

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
