import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class CompleteAccountRegisterationScreen extends ConsumerStatefulWidget {
  const CompleteAccountRegisterationScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteAccountRegisterationScreenState();
}

class _CompleteAccountRegisterationScreenState
    extends ConsumerState<CompleteAccountRegisterationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [Text("Hello")],
        ),
      ),
    );
  }
}
