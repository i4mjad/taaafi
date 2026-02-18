import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

/// A platform-aware checkbox that adapts to iOS and Android design guidelines
class PlatformCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final MaterialTapTargetSize? materialTapTargetSize;

  const PlatformCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
    this.materialTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (Platform.isIOS) {
      return GestureDetector(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value
                ? (activeColor ?? theme.primary[600])
                : Colors.transparent,
            border: Border.all(
              color: value
                  ? (activeColor ?? theme.primary[600]!)
                  : theme.grey[400]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: value
              ? Icon(
                  CupertinoIcons.check_mark,
                  size: 16,
                  color: checkColor ?? Colors.white,
                )
              : null,
        ),
      );
    }

    // Android/Material Design
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? theme.primary[600],
      checkColor: checkColor,
      materialTapTargetSize:
          materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// A checkbox with label for easier use
class PlatformCheckboxListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Color? activeColor;
  final Color? checkColor;
  final EdgeInsets? contentPadding;

  const PlatformCheckboxListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.activeColor,
    this.checkColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformCheckbox(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
              checkColor: checkColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

