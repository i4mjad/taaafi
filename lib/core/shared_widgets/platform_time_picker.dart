import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class PlatformTimePicker extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?>? onChanged;
  final String? label;
  final bool isDense;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool use24HourFormat;

  const PlatformTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.isDense = true,
    this.backgroundColor,
    this.padding,
    this.use24HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (Platform.isIOS) {
      return _buildIOSTimePicker(context, theme);
    } else {
      return _buildAndroidTimePicker(context, theme);
    }
  }

  Widget _buildAndroidTimePicker(BuildContext context, dynamic theme) {
    return GestureDetector(
      onTap: () => _showAndroidTimePicker(context),
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
                _formatTime(context),
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.clock,
              color: theme.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSTimePicker(BuildContext context, dynamic theme) {
    return GestureDetector(
      onTap: () => _showIOSTimePicker(context, theme),
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
                _formatTime(context),
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.clock,
              color: theme.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAndroidTimePicker(BuildContext context) async {
    HapticFeedback.lightImpact();

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: use24HourFormat,
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      onChanged?.call(selectedTime);
    }
  }

  void _showIOSTimePicker(BuildContext context, dynamic theme) {
    HapticFeedback.lightImpact();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
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
              // Time Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: use24HourFormat,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    value?.hour ?? TimeOfDay.now().hour,
                    value?.minute ?? TimeOfDay.now().minute,
                  ),
                  onDateTimeChanged: (DateTime dateTime) {
                    HapticFeedback.selectionClick();
                    onChanged?.call(TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context) {
    if (value == null) {
      return AppLocalizations.of(context).translate('select-time');
    }

    if (use24HourFormat) {
      return '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = value!.hourOfPeriod == 0 ? 12 : value!.hourOfPeriod;
      final period = value!.period == DayPeriod.am
          ? AppLocalizations.of(context).translate('am')
          : AppLocalizations.of(context).translate('pm');
      return '$hour:${value!.minute.toString().padLeft(2, '0')} $period';
    }
  }
}
