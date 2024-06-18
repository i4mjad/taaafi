import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';

//TODO: to be updated after the migeration from old account screen
//! RENAME THIS
class UpdatedAccountScreen extends ConsumerWidget {
  const UpdatedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar(context, ref, 'account'),
      body: Container(),
    );
  }
}
