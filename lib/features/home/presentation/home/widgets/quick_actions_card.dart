import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class QuickActionsCard extends ConsumerWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header
        Row(
          children: [
            WidgetsContainer(
              padding: const EdgeInsets.all(8),
              backgroundColor: theme.primary[50],
              borderRadius: BorderRadius.circular(8),
              child: Icon(
                LucideIcons.zap,
                color: theme.primary[600],
                size: 20,
              ),
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate("quick-actions"),
                    style: TextStyles.h6.copyWith(color: theme.grey[900]),
                  ),
                  Text(
                    localization.translate("quick-actions-description"),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points16),

        // Quick Action Buttons Grid
        _buildQuickActionsGrid(context, theme, localization),
      ],
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localization,
  ) {
    final actions = [
      _QuickAction(
        icon: LucideIcons.target,
        label: localization.translate("log-relapse"),
        color: theme.error[500]!,
        backgroundColor: theme.error[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to home screen (where user can log follow-ups)
          context.pushNamed(RouteNames.home.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.shield,
        label: localization.translate("emergency-help"),
        color: theme.warn[600]!,
        backgroundColor: theme.warn[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to community for emergency resources
          context.pushNamed(RouteNames.community.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.calendar,
        label: localization.translate("view-calendar"),
        color: theme.primary[600]!,
        backgroundColor: theme.primary[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.vault.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.bookOpen,
        label: localization.translate("add-diary-entry"),
        color: theme.success[600]!,
        backgroundColor: theme.success[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.diaries.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.users,
        label: localization.translate("community"),
        color: theme.secondary[600]!,
        backgroundColor: theme.secondary[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(RouteNames.community.name);
        },
      ),
      _QuickAction(
        icon: LucideIcons.trendingUp,
        label: localization.translate("view-progress"),
        color: theme.tint[600]!,
        backgroundColor: theme.tint[50]!,
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to vault for progress/statistics
          context.pushNamed(RouteNames.vault.name);
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionButton(action: action);
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionButton({
    required this.action,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.action.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: widget.action.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.action.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        widget.action.icon,
                        color: widget.action.color,
                        size: 16,
                      ),
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: Text(
                        widget.action.label,
                        style: TextStyles.footnote.copyWith(
                          color: widget.action.color,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
