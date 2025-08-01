import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class StreakDisplayWidget extends StatelessWidget {
  final int streakDays;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;

  const StreakDisplayWidget({
    super.key,
    required this.streakDays,
    this.fontSize,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E)
            .withValues(alpha: 0.1), // Success green color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trophy,
            size: iconSize ?? 12,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 4),
          Text(
            localizations
                .translate('days-streak')
                .replaceAll('{days}', streakDays.toString()),
            style: TextStyles.small.copyWith(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
