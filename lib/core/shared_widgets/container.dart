import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class WidgetsContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final double? cornerSmoothing;

  WidgetsContainer({
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
    this.cornerSmoothing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor ?? theme.primaryColor.withOpacity(0.1),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: (borderRadius ?? BorderRadius.circular(15)).topLeft.x,
            cornerSmoothing: cornerSmoothing ?? 1,
          ),
          side: borderSide ??
              BorderSide(
                color: theme.primaryColor.withOpacity(0.4),
                width: 1.0,
              ),
        ),
      ),
      child: child,
    );
  }
}
