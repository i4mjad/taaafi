import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/guard_usage_repository.dart';

class IosPickerControls extends ConsumerWidget {
  const IosPickerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    final auth = ref.watch(iosAuthStatusProvider);

    return auth.maybeWhen(
      data: (ok) {
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: ok
                  ? () async {
                      await iosPresentPicker();
                    }
                  : null,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Select apps & sites'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: ok
                  ? () async {
                      await iosStartMonitoring();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Hourly monitoring started')),
                      );
                    }
                  : null,
              child: const Text('Start monitoring'),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
