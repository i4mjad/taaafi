import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/guard_usage_repository.dart';
import '../../../../core/logging/focus_log.dart';

class IosAuthBanner extends ConsumerWidget {
  const IosAuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    final auth = ref.watch(iosAuthStatusProvider);

    return auth.when(
      // Don't show anything while loading to prevent flash
      loading: () {
        focusLog('IosAuthBanner: loading authorization status...');
        return const SizedBox.shrink();
      },
      // Don't show banner on error, just hide it
      error: (error, stack) {
        focusLog('IosAuthBanner: error checking status', data: error);
        return const SizedBox.shrink();
      },
      data: (ok) {
        focusLog('IosAuthBanner: auth status result', data: ok);
        
        // If authorized, don't show banner
        if (ok) {
          focusLog('IosAuthBanner: ✅ AUTHORIZED - hiding banner');
          return const SizedBox.shrink();
        }
        
        // Only show banner if definitely not authorized
        focusLog('IosAuthBanner: ❌ NOT AUTHORIZED - showing banner');
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.lock_outline),
          content: const Text(
              'Screen Time access is required to compute Focus Score on iOS.'),
          actions: [
            TextButton(
              onPressed: () async {
                focusLog('IosAuthBanner: Enable button tapped');
                try {
                  await iosRequestAuthorization();
                  focusLog('IosAuthBanner: authorization requested successfully');
                  // Invalidate to refresh status
                  ref.invalidate(iosAuthStatusProvider);
                  
                  // Also start monitoring if authorized
                  final newStatus = await iosGetAuthorizationStatus();
                  if (newStatus) {
                    focusLog('IosAuthBanner: starting monitoring...');
                    await iosStartMonitoring();
                  }
                } catch (e) {
                  focusLog('IosAuthBanner: error requesting authorization', data: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }
}
