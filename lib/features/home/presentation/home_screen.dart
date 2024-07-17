import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text("You are logged in"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
