import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';

class FellowshipScreen extends ConsumerWidget {
  const FellowshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar(context, ref, 'fellowship', false,true),
      body: Center(
        child: Text("Fellowship"),
      ),
    );
  }
}
