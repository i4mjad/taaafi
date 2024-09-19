import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final TextInputType inputType;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final FocusNode? focusNode;
  final double? width;
  final bool? enabled;
  final String? Function(String?) validator;

  const CustomTextField({
    Key? key,
    this.enabled,
    this.focusNode,
    required this.validator,
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
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isValid = true;
  String? _errorText;

  void _validate() {
    final error = widget.validator(widget.controller.text);
    setState(() {
      _isValid = error == null;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hint != null) ...[
          Text(
            widget.hint!,
            style: TextStyles.footnote,
          ),
          verticalSpace(Spacing.points4),
        ],
        Container(
          width: widget.width ?? MediaQuery.of(context).size.width - 32,
          decoration: ShapeDecoration(
            color: theme.primary[50],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius:
                    (widget.borderRadius ?? BorderRadius.circular(10.5))
                        .topLeft
                        .x,
                cornerSmoothing: 1,
              ),
              side: widget.borderSide ??
                  BorderSide(
                    color: _isValid ? theme.grey[100]! : theme.error[600]!,
                    width: 1,
                  ),
            ),
          ),
          child: TextFormField(
            enabled: widget.enabled ?? true,
            controller: widget.controller,
            textCapitalization: widget.textCapitalization,
            maxLength: 100,
            maxLines: 1,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.inputType,
            textAlign: TextAlign.start,
            validator: (value) {
              final error = widget.validator(value);
              setState(() {
                _isValid = error == null;
                _errorText = error;
              });
              return null;
            },
            onChanged: (value) {
              _validate();
            },
            style: TextStyles.footnote,
            decoration: InputDecoration(
              prefixIcon: Icon(
                widget.prefixIcon,
                color: theme.grey[900],
              ),
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 16, bottom: 16),
            ),
          ),
        ),
        if (_errorText != null) ...[
          verticalSpace(Spacing.points4),
          Container(
            constraints: BoxConstraints(
              maxWidth: widget.width ?? MediaQuery.of(context).size.width - 32,
            ),
            child: Text(
              _errorText!,
              style: TextStyles.small.copyWith(color: theme.error[600]),
              softWrap: true,
            ),
          ),
        ],
      ],
    );
  }
}
