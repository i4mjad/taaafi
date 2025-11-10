import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds iOS DeviceActivityReport to show today's Screen Time data
class IosActivityReportView extends StatelessWidget {
  const IosActivityReportView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const Center(
        child: Text('Only available on iOS'),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 600,
      ),
      child: const UiKitView(
        viewType: 'DeviceActivityReportView',
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}

