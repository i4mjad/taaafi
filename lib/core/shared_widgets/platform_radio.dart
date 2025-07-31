import 'package:flutter/material.dart';
import 'dart:io';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class PlatformRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? title;
  final String? subtitle;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const PlatformRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isSelected = value == groupValue;

    Widget radioWidget;
    if (Platform.isIOS) {
      // Use a custom iOS-style radio button
      radioWidget = GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(value) : null,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? (isSelected
                      ? (activeColor ?? theme.primary[600]!)
                      : theme.grey[400]!)
                  : theme.grey[300]!,
              width: 2,
            ),
            color: isSelected
                ? (activeColor ?? theme.primary[600]!)
                : Colors.transparent,
          ),
          child: isSelected
              ? Icon(
                  Icons.circle,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
      );
    } else {
      // Use Material Design radio button
      radioWidget = Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        activeColor: activeColor ?? theme.primary[600],
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    if (title == null && subtitle == null) {
      return radioWidget;
    }

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: enabled && onChanged != null ? () => onChanged!(value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              radioWidget,
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyles.footnote.copyWith(
                          color: enabled ? theme.grey[900] : theme.grey[500],
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    if (subtitle != null) ...[
                      verticalSpace(Spacing.points4),
                      Text(
                        subtitle!,
                        style: TextStyles.small.copyWith(
                          color: enabled ? theme.grey[600] : theme.grey[400],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlatformRadioGroup<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<PlatformRadioOption<T>> options;
  final String? title;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final Color? activeColor;

  const PlatformRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.title,
    this.enabled = true,
    this.padding,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title!,
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          verticalSpace(Spacing.points8),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.grey[200]!, width: 1),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isLast = index == options.length - 1;

              return Column(
                children: [
                  PlatformRadio<T>(
                    value: option.value,
                    groupValue: value,
                    onChanged: enabled ? onChanged : null,
                    title: option.title,
                    subtitle: option.subtitle,
                    activeColor: activeColor,
                    enabled: enabled,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: theme.grey[100],
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class PlatformRadioOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const PlatformRadioOption({
    required this.value,
    required this.title,
    this.subtitle,
  });
}
