import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';

class PremiumCtaAppBarIcon extends ConsumerWidget {
  const PremiumCtaAppBarIcon({super.key});
//TODO: consider wraping this to a checker for the subscription status, if the user is subscibed show them a page that will guide them to the features and allow them to access those features.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

        return GestureDetector(
          onTap: () async {
            // For testing: Toggle subscription status and save to SharedPreferences
            try {
              final notifier = ref.read(subscriptionNotifierProvider.notifier);
              final currentStatus =
                  ref.read(subscriptionNotifierProvider).valueOrNull;

              if (currentStatus?.status == SubscriptionStatus.plus &&
                  currentStatus?.isActive == true) {
                // Switch to FREE
                await notifier.updateSubscriptionForTesting(
                  const SubscriptionInfo(
                    status: SubscriptionStatus.free,
                    isActive: false,
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '🔓 Test: Switched to FREE (Saved to SharedPreferences)'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                // Switch to PLUS
                await notifier.updateSubscriptionForTesting(
                  SubscriptionInfo(
                    status: SubscriptionStatus.plus,
                    isActive: true,
                    expirationDate:
                        DateTime.now().add(const Duration(days: 30)),
                    productId: 'test_plus_subscription',
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '👑 Test: Switched to PLUS (Saved to SharedPreferences)'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error toggling subscription: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Icon(
                  Ta3afiPlatformIcons.plus_icon,
                  color:
                      hasSubscription ? Colors.green : const Color(0xFFFEBA01),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
