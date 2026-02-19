import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds the iOS DeviceActivityReport SwiftUI view as a platform view.
/// This is the ONLY way to display actual usage data on iOS — the report
/// extension is sandboxed and cannot write data to shared storage.
///
/// The DeviceActivityMonitor extension handles programmatic data via
/// threshold events written to app group UserDefaults.
///
/// On Android this renders nothing.
class IosUsageReportView extends StatefulWidget {
  /// Called after the platform view has been created.
  final VoidCallback? onReady;

  const IosUsageReportView({super.key, this.onReady});

  @override
  State<IosUsageReportView> createState() => _IosUsageReportViewState();
}

class _IosUsageReportViewState extends State<IosUsageReportView> {
  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: UiKitView(
          viewType: 'com.taaafi.fort/usageReportView',
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (_) {
            widget.onReady?.call();
          },
        ),
      ),
    );
  }
}
