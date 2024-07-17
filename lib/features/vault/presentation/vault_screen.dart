import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'vault', false, true),
      body: Center(
        child: Text("Vault"),
      ),
    );
  }
}
