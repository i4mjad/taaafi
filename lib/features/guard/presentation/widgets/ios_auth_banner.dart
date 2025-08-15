import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/guard_usage_repository.dart';

class IosAuthBanner extends ConsumerWidget {
  const IosAuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    final auth = ref.watch(iosAuthStatusProvider);

    return auth.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ok) {
        if (ok) return const SizedBox.shrink();
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.lock_outline),
          content: const Text(
              'Screen Time access is required to compute Focus Score on iOS.'),
          actions: [
            TextButton(
              onPressed: () async {
                await iosRequestAuthorization();
                ref.invalidate(iosAuthStatusProvider);
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }
}
