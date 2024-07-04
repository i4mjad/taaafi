import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CustomSegmentedButton extends ConsumerWidget {
  final String label;
  final List<SegmentedButtonOption> options;
  final SegmentedButtonOption selectedOption;
  final ValueChanged<SegmentedButtonOption> onChanged;

  const CustomSegmentedButton({
    Key? key,
    required this.label,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.footnote.copyWith(
            color: theme.grey[900],
          ),
        ),
        verticalSpace(Spacing.points8),
        Container(
          width: MediaQuery.of(context).size.width,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ToggleButtons(
                renderBorder: true,
                constraints: BoxConstraints.expand(
                  width: (constraints.maxWidth - (options.length + 2)) /
                      options.length,
                ),
                borderRadius: BorderRadius.circular(5),
                children: options
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          AppLocalizations.of(context)
                              .translate(option.translationKey),
                          style: TextStyles.body,
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
        ),
      ],
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
