import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/guard/application/usage_access_provider.dart';
import 'package:reboot_app_3/features/guard/application/usage_permissions.dart';

class UsageAccessBanner extends ConsumerWidget {
  const UsageAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAccessAsync = ref.watch(usageAccessGrantedProvider);

    return usageAccessAsync.when(
      data: (isGranted) {
        if (!isGranted) {
          // QA Instrumentation - Log when banner is shown
          print('📱 [QA] Usage Access Banner shown (permission missing)');

          return MaterialBanner(
            leading: const Icon(Icons.lock_outline),
            content:
                const Text('Usage Access is required to compute Focus Score.'),
            actions: [
              TextButton(
                onPressed: () async {
                  // QA Instrumentation - Log when Enable CTA is tapped
                  print('📱 [QA] Usage Access Banner - "Enable" CTA tapped');

                  await openUsageAccessSettings();
                  // Refresh the provider after settings are opened
                  ref.invalidate(usageAccessGrantedProvider);
                },
                child: const Text('Enable'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
