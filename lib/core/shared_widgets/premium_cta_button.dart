import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';

class PremiumCtaAppBarIcon extends ConsumerWidget {
  const PremiumCtaAppBarIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

        return GestureDetector(
          onTap: () async {
            // TODO: Change the functionality of this button to prompt the user to upgrade to premium,
            // if they are a premium user, show a modal with the features they get with premium
            // with the ability to access those features from that screen.

            // For now, toggle subscription status for testing
            Future(() async {
              final notifier = ref.read(subscriptionNotifierProvider.notifier);
              final currentStatus =
                  ref.read(subscriptionNotifierProvider).valueOrNull;

              if (currentStatus?.status == SubscriptionStatus.plus &&
                  currentStatus?.isActive == true) {
                // Switch to free
                await notifier.updateSubscriptionForTesting(
                  const SubscriptionInfo(
                    status: SubscriptionStatus.free,
                    isActive: false,
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test: Switched to FREE')),
                  );
                }
              } else {
                // Switch to plus
                await notifier.updateSubscriptionForTesting(
                  SubscriptionInfo(
                    status: SubscriptionStatus.plus,
                    isActive: true,
                    expirationDate:
                        DateTime.now().add(const Duration(days: 30)),
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test: Switched to PLUS')),
                  );
                }
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Ta3afiPlatformIcons.plus_icon,
              color: const Color(0xFFFEBA01),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
