import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CustomSegmentedButton extends ConsumerWidget {
  final String? label;

  final List<SegmentedButtonOption> options;
  final SegmentedButtonOption selectedOption;
  final ValueChanged<SegmentedButtonOption> onChanged;

  const CustomSegmentedButton({
    Key? key,
    this.label,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyles.footnote.copyWith(
              color: theme.primary[900],
            ),
          ),
        if (label != null) verticalSpace(Spacing.points8),
        Platform.isIOS
            ? _buildIOSSegmentedControl(context, theme)
            : _buildAndroidSegmentedButton(context, theme),
      ],
    );
  }

  Widget _buildIOSSegmentedControl(BuildContext context, dynamic theme) {
    final selectedIndex = options.indexOf(selectedOption);
    Map<int, Widget> children = {};

    for (int i = 0; i < options.length; i++) {
      final isSelected = i == selectedIndex;
      children[i] = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          AppLocalizations.of(context).translate(options[i].translationKey),
          style: TextStyles.body.copyWith(
            color: isSelected ? theme.grey[50] : theme.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              color: theme.primary[600]!,
              width: 1.5,
            ),
          ),
        ),
        child: CupertinoSlidingSegmentedControl<int>(
          children: children,
          onValueChanged: (int? index) {
            if (index != null) {
              onChanged(options[index]);
            }
          },
          groupValue: selectedIndex,
          backgroundColor: theme.backgroundColor,
          thumbColor: theme.primary[600],
        ),
      ),
    );
  }

  Widget _buildAndroidSegmentedButton(BuildContext context, dynamic theme) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ToggleButtons(
            renderBorder: true,
            constraints: BoxConstraints.expand(
              width: (constraints.maxWidth - (options.length + 2)) /
                  options.length,
            ),
            borderRadius: BorderRadius.circular(8),
            children: options
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      AppLocalizations.of(context)
                          .translate(option.translationKey),
                      style: TextStyles.body.copyWith(),
                    ),
                  ),
                )
                .toList(),
            isSelected: options.map((e) => e == selectedOption).toList(),
            onPressed: (int index) {
              onChanged(options[index]);
            },
            selectedBorderColor: theme.primary[600],
            selectedColor: theme.grey[50],
            fillColor: theme.primary[600],
            color: theme.primary[600],
          );
        },
      ),
    );
  }
}

class SegmentedButtonOption {
  String value;
  String translationKey;
  SegmentedButtonOption({
    required this.value,
    required this.translationKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentedButtonOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
