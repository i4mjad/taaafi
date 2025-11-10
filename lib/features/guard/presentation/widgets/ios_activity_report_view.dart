import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/logging/focus_log.dart';

/// Embeds iOS DeviceActivityReport to show today's Screen Time data
class IosActivityReportView extends StatefulWidget {
  const IosActivityReportView({super.key});

  @override
  State<IosActivityReportView> createState() => _IosActivityReportViewState();
}

class _IosActivityReportViewState extends State<IosActivityReportView> {
  @override
  void initState() {
    super.initState();
    focusLog('📱 [REPORT WIDGET] === IosActivityReportView: initState ===');
  }

  @override
  Widget build(BuildContext context) {
    focusLog('📱 [REPORT WIDGET] === IosActivityReportView: build ===');
    
    if (!Platform.isIOS) {
      focusLog('📱 [REPORT WIDGET] build: not iOS, returning placeholder');
      return const Center(
        child: Text('Only available on iOS'),
      );
    }

    focusLog('📱 [REPORT WIDGET] build: creating UiKitView with type "DeviceActivityReportView"');
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 600,
      ),
      child: UiKitView(
        viewType: 'DeviceActivityReportView',
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          focusLog('📱 [REPORT WIDGET] onPlatformViewCreated: ✅ native view created with id=$id');
        },
      ),
    );
  }

  @override
  void dispose() {
    focusLog('📱 [REPORT WIDGET] === IosActivityReportView: dispose ===');
    super.dispose();
  }
}

