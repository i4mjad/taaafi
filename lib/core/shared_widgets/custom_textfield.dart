import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CustomTextField extends ConsumerWidget {
  final TextEditingController controller;
  final String? hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final TextInputType inputType;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final double? width;
  final bool? enabled;

  const CustomTextField({
    Key? key,
    this.enabled,
    this.borderRadius,
    this.borderSide,
    this.width,
    required this.controller,
    this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    required this.inputType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (BuildContext context) {
            if (hint != null) {
              return Column(
                children: [
                  Text(
                    hint!,
                    style: TextStyles.footnote,
                  ),
                  verticalSpace(Spacing.points4),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),
        Container(
          width: width ?? MediaQuery.of(context).size.width - 32,
          decoration: ShapeDecoration(
            color: theme.grey[50],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius:
                    (borderRadius ?? BorderRadius.circular(10.5)).topLeft.x,
                cornerSmoothing: 1,
              ),
              side: borderSide ??
                  BorderSide(
                    color: theme.grey[100]!,
                    width: 1,
                  ),
            ),
          ),
          child: TextField(
            enabled: enabled ?? true,
            controller: controller,
            textCapitalization: textCapitalization,
            maxLength: 100,
            maxLines: 1,
            obscureText: obscureText,
            keyboardType: inputType,
            textAlign: TextAlign.start,
            style: TextStyles.footnote,
            decoration: InputDecoration(
              prefixIcon: Icon(
                prefixIcon,
                color: theme.primary[600],
              ),
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 16, bottom: 16),
            ),
          ),
        ),
      ],
    );
  }
}
