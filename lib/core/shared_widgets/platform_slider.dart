import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

/// A platform-aware slider component that adapts to iOS (Cupertino) and Android (Material)
/// 
/// Features:
/// - Platform-specific styling (CupertinoSlider for iOS, Slider for Android)
/// - Optional label and subtitle
/// - Optional value display (current, min, max)
/// - Customizable colors and padding
/// - Divisions support for discrete values
/// 
/// Example usage:
/// ```dart
/// PlatformSlider(
///   value: selectedValue.toDouble(),
///   min: 0.0,
///   max: 50.0,
///   divisions: 50,
///   label: 'Select Capacity',
///   subtitle: 'Choose the maximum number of members',
///   valueFormatter: (value) => '${value.toInt()} members',
///   showValue: true,
///   showMinMaxLabels: true,
///   valueDisplayPosition: ValueDisplayPosition.above,
///   onChanged: (value) => setState(() => selectedValue = value.toInt()),
/// )
/// ```
class PlatformSlider extends StatelessWidget {
  /// Current value of the slider
  final double value;

  /// Callback when slider value changes
  final ValueChanged<double>? onChanged;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of discrete divisions (null for continuous)
  final int? divisions;

  /// Optional label text above the slider
  final String? label;

  /// Optional subtitle text below the label
  final String? subtitle;

  /// Optional value formatter (e.g., to show "5 members" instead of "5.0")
  final String Function(double)? valueFormatter;

  /// Show current value display
  final bool showValue;

  /// Show min/max labels
  final bool showMinMaxLabels;

  /// Active track color
  final Color? activeColor;

  /// Inactive track color
  final Color? inactiveColor;

  /// Thumb color (iOS only)
  final Color? thumbColor;

  /// Container padding
  final EdgeInsetsGeometry? padding;

  /// Value display position (above, below, or inline)
  final ValueDisplayPosition valueDisplayPosition;

  const PlatformSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.label,
    this.subtitle,
    this.valueFormatter,
    this.showValue = true,
    this.showMinMaxLabels = false,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.padding,
    this.valueDisplayPosition = ValueDisplayPosition.above,
  }) : assert(value >= min && value <= max, 'Value must be between min and max');

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label and subtitle
          if (label != null || subtitle != null) ...[
            _buildLabelSection(theme),
            verticalSpace(Spacing.points8),
          ],

          // Value display (above position)
          if (showValue && valueDisplayPosition == ValueDisplayPosition.above) ...[
            _buildValueDisplay(theme),
            verticalSpace(Spacing.points8),
          ],

          // Slider with optional inline value
          Row(
            children: [
              // Min label
              if (showMinMaxLabels) ...[
                _buildMinMaxLabel(min, theme),
                horizontalSpace(Spacing.points8),
              ],

              // Slider
              Expanded(
                child: _buildSlider(theme),
              ),

              // Max label
              if (showMinMaxLabels) ...[
                horizontalSpace(Spacing.points8),
                _buildMinMaxLabel(max, theme),
              ],

              // Inline value display
              if (showValue && valueDisplayPosition == ValueDisplayPosition.inline) ...[
                horizontalSpace(Spacing.points12),
                _buildValueDisplay(theme),
              ],
            ],
          ),

          // Value display (below position)
          if (showValue && valueDisplayPosition == ValueDisplayPosition.below) ...[
            verticalSpace(Spacing.points8),
            _buildValueDisplay(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelSection(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyles.footnote.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        if (subtitle != null) ...[
          verticalSpace(Spacing.points4),
          Text(
            subtitle!,
            style: TextStyles.small.copyWith(
              height: 1.5,
              color: theme.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueDisplay(dynamic theme) {
    final displayValue = valueFormatter?.call(value) ?? value.toStringAsFixed(divisions != null ? 0 : 1);
    
    return Text(
      displayValue,
      style: TextStyles.h5.copyWith(
        color: theme.grey[900],
        fontWeight: FontWeight.w600,
      ),
      textAlign: valueDisplayPosition == ValueDisplayPosition.inline 
          ? TextAlign.right 
          : TextAlign.center,
    );
  }

  Widget _buildMinMaxLabel(double val, dynamic theme) {
    final displayValue = valueFormatter?.call(val) ?? val.toStringAsFixed(divisions != null ? 0 : 1);
    
    return Text(
      displayValue,
      style: TextStyles.small.copyWith(
        color: theme.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSlider(dynamic theme) {
    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        activeColor: activeColor ?? theme.primary[600],
        thumbColor: thumbColor ?? theme.primary[600],
      );
    } else {
      return Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: valueFormatter?.call(value) ?? value.toStringAsFixed(divisions != null ? 0 : 1),
        onChanged: onChanged,
        activeColor: activeColor ?? theme.primary[600],
        inactiveColor: inactiveColor ?? theme.grey[300],
      );
    }
  }
}

/// Position of the value display relative to the slider
enum ValueDisplayPosition {
  /// Display value above the slider
  above,
  
  /// Display value below the slider
  below,
  
  /// Display value inline to the right of the slider
  inline,
}

