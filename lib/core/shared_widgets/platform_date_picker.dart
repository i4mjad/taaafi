import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';

enum PlatformDatePickerMode { dateOnly, dateTime }

class PlatformDatePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final String? hint;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData? prefixIcon;
  final bool enabled;
  final String? Function(String?)? validator;
  final String Function(DateTime) dateFormatter;
  final PlatformDatePickerMode mode;

  const PlatformDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.label,
    this.firstDate,
    this.lastDate,
    this.prefixIcon,
    this.enabled = true,
    this.validator,
    required this.dateFormatter,
    this.mode = PlatformDatePickerMode.dateOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final controller = TextEditingController(
      text: value != null ? dateFormatter(value!) : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyles.footnote.copyWith(
              color: theme.primary[900],
            ),
          ),
          verticalSpace(Spacing.points8),
        ],
        GestureDetector(
          onTap: enabled ? () => _showDatePicker(context) : null,
          child: AbsorbPointer(
            child: CustomTextField(
              controller: controller,
              hint:
                  hint ?? AppLocalizations.of(context).translate('select-date'),
              prefixIcon: prefixIcon ?? LucideIcons.calendar,
              inputType: TextInputType.datetime,
              enabled: enabled,
              validator: validator ??
                  (value) {
                    if (this.value == null && enabled) {
                      return AppLocalizations.of(context)
                          .translate('field-required');
                    }
                    return null;
                  },
            ),
          ),
        ),
      ],
    );
  }

  DateTime _getValidInitialDate() {
    // If we have a selected value, use it
    if (value != null) return value!;

    final now = DateTime.now();

    // If no constraints, use now
    if (firstDate == null && lastDate == null) return now;

    // If now is within range, use it
    if ((firstDate == null || !now.isBefore(firstDate!)) &&
        (lastDate == null || !now.isAfter(lastDate!))) {
      return now;
    }

    // If now is before firstDate, use firstDate
    if (firstDate != null && now.isBefore(firstDate!)) {
      return firstDate!;
    }

    // If now is after lastDate, use a reasonable date before lastDate
    if (lastDate != null && now.isAfter(lastDate!)) {
      // For birth dates (lastDate around 2010), default to a reasonable year like 1995
      if (lastDate!.year <= 2015) {
        return DateTime(1995, 6, 15); // Mid-year date for better UX
      }
      return lastDate!;
    }

    return now;
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final theme = AppTheme.of(context);
    DateTime? selectedDate;

    if (Platform.isIOS) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: 300,
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                        style: TextStyles.body.copyWith(color: theme.grey[600]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (selectedDate != null) {
                          onChanged?.call(selectedDate);
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context).translate('done'),
                        style:
                            TextStyles.body.copyWith(color: theme.primary[600]),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode == PlatformDatePickerMode.dateTime
                      ? CupertinoDatePickerMode.dateAndTime
                      : CupertinoDatePickerMode.date,
                  initialDateTime: _getValidInitialDate(),
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Android implementation
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _getValidInitialDate(),
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
      );

      if (selectedDate != null && mode == PlatformDatePickerMode.dateTime) {
        // If date+time mode, also show time picker
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime:
              value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
        );

        if (selectedTime != null) {
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        }
      }

      if (selectedDate != null) {
        onChanged?.call(selectedDate);
      }
    }
  }
}
