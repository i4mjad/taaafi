import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Plus subscription color
const Color plusColor = Color(0xFFFEBA01);

class PlusBadgeWidget extends StatelessWidget {
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;

  const PlusBadgeWidget({
    super.key,
    this.fontSize,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: plusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: plusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.crown,
            size: iconSize ?? 10,
            color: plusColor,
          ),
          const SizedBox(width: 3),
          Text(
            localizations.translate('plus'),
            style: TextStyles.tiny.copyWith(
              color: plusColor,
              fontWeight: FontWeight.w600,
              fontSize: fontSize ?? 10,
            ),
          ),
        ],
      ),
    );
  }
}
