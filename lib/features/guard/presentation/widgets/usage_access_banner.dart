import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/guard/application/usage_access_provider.dart';
// Removed unused import: usage_permissions
import 'package:reboot_app_3/features/guard/data/guard_usage_repository.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class UsageAccessBanner extends ConsumerWidget {
  const UsageAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAccessAsync = ref.watch(usageAccessGrantedProvider);
    final localizations = AppLocalizations.of(context);

    return usageAccessAsync.when(
      data: (isGranted) {
        if (!isGranted) {
          // QA Instrumentation - Log when banner is shown
          print('📱 [QA] Usage Access Banner shown (permission missing)');

          return MaterialBanner(
            leading: const Icon(Icons.lock_outline),
            content: Text(localizations.translate('usage_access_required')),
            actions: [
              TextButton(
                onPressed: () async {
                  // QA Instrumentation - Log when Enable CTA is tapped
                  print('📱 [QA] Usage Access Banner - "Enable" CTA tapped');

                  // Use unified facade for Android
                  await const FocusFacade()
                      .requestPermissionsAndStartMonitoring();
                  // Refresh the provider after settings are opened
                  ref.invalidate(usageAccessGrantedProvider);
                },
                child: Text(localizations.translate('enable')),
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
