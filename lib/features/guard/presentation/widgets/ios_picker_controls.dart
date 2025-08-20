import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import 'ios_picker_controls_modal.dart';

class IosPickerControls extends ConsumerWidget {
  const IosPickerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => _showPickerControlsModal(context),
      icon: Icon(
        LucideIcons.settings,
        color: theme.grey[700],
        size: 24,
      ),
      tooltip: localizations.translate('focus_controls'),
    );
  }

  void _showPickerControlsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const IosPickerControlsModal(),
    );
  }
}
