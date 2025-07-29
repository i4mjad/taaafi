import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class PlatformSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? subtitle;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsetsGeometry? padding;

  const PlatformSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.activeColor,
    this.inactiveColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    Widget switchWidget;
    if (Platform.isIOS) {
      switchWidget = CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? theme.primary[600],
        trackColor: inactiveColor ?? theme.grey[300],
      );
    } else {
      switchWidget = Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? theme.primary[600],
        inactiveTrackColor: inactiveColor ?? theme.grey[300],
      );
    }

    if (label == null && subtitle == null) {
      return switchWidget;
    }

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (subtitle != null) ...[
                  verticalSpace(Spacing.points4),
                  Text(
                    subtitle!,
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          horizontalSpace(Spacing.points16),
          switchWidget,
        ],
      ),
    );
  }
}
