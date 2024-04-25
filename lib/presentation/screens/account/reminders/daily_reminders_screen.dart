import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';

class LockAppScreen extends StatelessWidget {
  const LockAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithSettings(context, "lock-app"),
      body: SingleChildScrollView(
        child: Column(),
      ),
    );
  }
}
