import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class RoleChip extends StatelessWidget {
  final String role;

  const RoleChip({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Don't show chip for regular members
    if (role.toLowerCase() == 'member') {
      return const SizedBox.shrink();
    }

    final roleData = _getRoleData(role.toLowerCase(), localizations);

    return WidgetsContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      backgroundColor: roleData.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: roleData.color.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleData.icon,
            size: 12,
            color: roleData.color,
          ),
          const SizedBox(width: 4),
          Text(
            roleData.displayName,
            style: TextStyles.small.copyWith(
              color: roleData.color,
            ),
          ),
        ],
      ),
    );
  }

  _RoleData _getRoleData(String role, AppLocalizations localizations) {
    switch (role) {
      case 'admin':
        return _RoleData(
          displayName: localizations.translate('admin'),
          icon: LucideIcons.shield,
          color: const Color(0xFFDC2626), // Red color for admin
        );
      case 'founder':
        return _RoleData(
          displayName: localizations.translate('founder'),
          icon: LucideIcons.personStanding,
          color: const Color(0xFF7C3AED), // Purple color for moderator
        );
      case 'member':
      default:
        return _RoleData(
          displayName: localizations.translate('member'),
          icon: LucideIcons.user,
          color: const Color(0xFF6B7280), // Gray color for member
        );
    }
  }
}

class _RoleData {
  final String displayName;
  final IconData icon;
  final Color color;

  _RoleData({
    required this.displayName,
    required this.icon,
    required this.color,
  });
}
