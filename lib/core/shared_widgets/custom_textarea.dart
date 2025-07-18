import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CustomTextArea extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final String? Function(String?) validator;
  final int maxLength;
  final int maxLines;
  final double? height;

  const CustomTextArea({
    Key? key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
    required this.validator,
    this.maxLength = 220,
    this.maxLines = 6,
    this.height,
  }) : super(key: key);

  @override
  State<CustomTextArea> createState() => _CustomTextAreaState();
}

class _CustomTextAreaState extends State<CustomTextArea> {
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
        Container(
          height: widget.height ?? 120,
          width: double.infinity,
          decoration: ShapeDecoration(
            color: theme.backgroundColor,
            shadows: [
              BoxShadow(
                color: Color.fromRGBO(50, 50, 93, 0.25),
                blurRadius: 5,
                spreadRadius: -1,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 3,
                spreadRadius: -1,
                offset: Offset(0, 1),
              ),
            ],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 10.5,
                cornerSmoothing: 1,
              ),
              side: BorderSide(
                color: _isValid ? theme.grey[600]! : theme.error[600]!,
                width: 0.75,
              ),
            ),
          ),
          child: TextFormField(
            enabled: widget.enabled,
            controller: widget.controller,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyles.footnote,
            onChanged: (value) {
              _validate();
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyles.footnote.copyWith(
                color: theme.grey[500],
                height: 1.3,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: 8, left: 16, right: 8),
                child: Icon(
                  widget.prefixIcon,
                  color: theme.grey[900],
                  size: 20,
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 44,
                minHeight: 32,
              ),
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                top: 16,
                bottom: 16,
                right: 16,
                left: 4,
              ),
            ),
          ),
        ),
        verticalSpace(Spacing.points8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_errorText != null)
              Expanded(
                child: Text(
                  _errorText!,
                  style: TextStyles.small.copyWith(color: theme.error[600]),
                ),
              )
            else
              SizedBox.shrink(),
            Text(
              '${widget.controller.text.length}/${widget.maxLength}',
              style: TextStyles.small.copyWith(
                color: widget.controller.text.length > widget.maxLength
                    ? theme.error[600]
                    : theme.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
