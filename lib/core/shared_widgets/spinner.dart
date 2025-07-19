import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class Spinner extends ConsumerWidget {
  const Spinner({super.key, this.strokeWidth = 3, this.valueColor});
  final double strokeWidth;
  final Color? valueColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return CircularProgressIndicator(
      color: theme.primary[500],
      strokeWidth: strokeWidth,
      valueColor:
          AlwaysStoppedAnimation<Color>(valueColor ?? theme.primary[500]!),
    );
  }
}
