import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds the iOS DeviceActivityReport SwiftUI view as a platform view.
/// When this widget renders, iOS triggers the DeviceActivityReportExtension
/// which aggregates usage data and writes it to shared UserDefaults.
///
/// On Android this renders nothing.
class IosUsageReportTrigger extends StatefulWidget {
  /// Called after the platform view has been created and a short delay
  /// has passed (giving the extension time to process data).
  final VoidCallback? onDataReady;

  const IosUsageReportTrigger({super.key, this.onDataReady});

  @override
  State<IosUsageReportTrigger> createState() => _IosUsageReportTriggerState();
}

class _IosUsageReportTriggerState extends State<IosUsageReportTrigger> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    return SizedBox(
      // Minimal size — the view is just a trigger, not visible to the user
      height: 1,
      width: 1,
      child: UiKitView(
        viewType: 'com.taaafi.fort/usageReportView',
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (_) {
          // Give the extension a few seconds to process and write data
          _timer = Timer(const Duration(seconds: 3), () {
            widget.onDataReady?.call();
          });
        },
      ),
    );
  }
}
