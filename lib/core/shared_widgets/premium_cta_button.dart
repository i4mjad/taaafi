import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

class PremiumCtaAppBarIcon extends ConsumerWidget {
  const PremiumCtaAppBarIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

        return GestureDetector(
          onTap: () {
            // Navigate based on subscription status
            if (hasSubscription) {
              // User is subscribed: Navigate to features guide
              context.pushNamed(RouteNames.plusFeaturesGuide.name);
            } else {
              // User is not subscribed: Navigate to subscription screen
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return const TaaafiPlusSubscriptionScreen();
                  });
            }
          },
          child: Stack(
            children: [
              Icon(
                Ta3afiPlatformIcons.plus,
                color: hasSubscription ? Colors.green : const Color(0xFFFEBA01),
                // size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}
