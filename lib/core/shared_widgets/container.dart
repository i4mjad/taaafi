import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class WidgetsContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final double? cornerSmoothing;
  final List<BoxShadow>? boxShadow;

  WidgetsContainer(
      {required this.child,
      this.width,
      this.height,
      this.padding,
      this.backgroundColor,
      this.borderRadius,
      this.borderSide,
      this.cornerSmoothing,
      this.boxShadow});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final contextWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor ?? theme.primary.withValues(alpha: 0.1),
        shadows: boxShadow,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius:
                (borderRadius ?? BorderRadius.circular(10.5)).topLeft.x,
            cornerSmoothing: cornerSmoothing ?? 1,
          ),
          side: borderSide ??
              BorderSide(
                color: theme.primary.withValues(alpha: 0.4),
                width: 1.0,
              ),
        ),
      ),
      child: child,
    );
  }
}
