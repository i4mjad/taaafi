import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class PlatformDropdown<T> extends StatelessWidget {
  final T? value;
  final List<PlatformDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final bool isDense;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const PlatformDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.isDense = true,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (Platform.isIOS) {
      return _buildIOSDropdown(context, theme);
    } else {
      return _buildAndroidDropdown(context, theme);
    }
  }

  Widget _buildAndroidDropdown(BuildContext context, dynamic theme) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyles.footnote.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            horizontalSpace(Spacing.points12),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: isDense,
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: theme.grey[600],
                  size: 16,
                ),
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
                items: items
                    .map((item) => DropdownMenuItem<T>(
                          value: item.value,
                          child: Text(item.label),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSDropdown(BuildContext context, dynamic theme) {
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );

    return GestureDetector(
      onTap: () => _showIOSPicker(context, theme),
      child: Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              horizontalSpace(Spacing.points12),
            ],
            Expanded(
              child: Text(
                selectedItem.label,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              color: theme.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showIOSPicker(BuildContext context, dynamic theme) {
    HapticFeedback.lightImpact();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 260,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header with Done button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: TextStyles.body.copyWith(
                          color: theme.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      const SizedBox(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppLocalizations.of(context).translate('done'),
                        style: TextStyles.body.copyWith(
                          color: theme.primary[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: items
                        .indexWhere((item) => item.value == value)
                        .clamp(0, items.length - 1),
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    HapticFeedback.selectionClick();
                    onChanged?.call(items[selectedItem].value);
                  },
                  children: items
                      .map((item) => Center(
                            child: Text(
                              item.label,
                              style: TextStyles.body.copyWith(
                                color: theme.grey[900],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlatformDropdownItem<T> {
  final T value;
  final String label;

  const PlatformDropdownItem({
    required this.value,
    required this.label,
  });
}
