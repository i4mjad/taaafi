import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Demo widget to test the new purchase success flow
/// This simulates what happens after a successful purchase
class PurchaseSuccessDemo extends ConsumerWidget {
  const PurchaseSuccessDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Success Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Simulate Purchase Success Flow',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // This simulates what happens after successful purchase
                context.pushNamed(RouteNames.plusFeaturesGuide.name,
                    extra: {'fromPurchase': true});
              },
              child: Text('Test: Navigate to Plus Features Guide'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // This simulates normal navigation (without purchase success)
                context.pushNamed(RouteNames.plusFeaturesGuide.name);
              },
              child: Text('Test: Normal Plus Features Guide'),
            ),
          ],
        ),
      ),
    );
  }
}
