import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class OngoingActivitiyScreen extends ConsumerWidget {
  const OngoingActivitiyScreen(this.ongoingActivitiyId, {super.key});

  final String ongoingActivitiyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, ongoingActivitiyId, false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
