import 'package:flutter/material.dart';
import 'package:reboot_app_3/features/guard/application/first_run_gate.dart';
import 'package:reboot_app_3/features/guard/application/usage_permissions.dart';

/// Shows an educational bottom sheet about usage access permissions
Future<void> showUsageAccessIntroSheet(BuildContext context) async {
  // QA Instrumentation - Log when intro sheet is shown
  print('📱 [QA] Usage Access Intro Sheet shown');

  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.security,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Allow Usage Access',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Body text
            Text(
              'To provide accurate Focus Scores, Taaafi needs access to your app usage data.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Benefits list
            _BenefitItem(
              icon: Icons.insights,
              title: 'Accurate Focus Tracking',
              description:
                  'See exactly how much time you spend in different apps',
            ),

            const SizedBox(height: 12),

            _BenefitItem(
              icon: Icons.local_fire_department,
              title: 'Personal Insights',
              description: 'Get personalized recommendations to improve focus',
            ),

            const SizedBox(height: 12),

            _BenefitItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy First',
              description: 'All data stays on your device and is never shared',
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // QA Instrumentation - Log "Not now" action
                      print('📱 [QA] Usage Access Intro - "Not now" tapped');

                      await setHasSeenUsageAccessIntro(true);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      // QA Instrumentation - Log "Enable" action
                      print('📱 [QA] Usage Access Intro - "Enable" tapped');

                      await setHasSeenUsageAccessIntro(true);
                      await openUsageAccessSettings();

                      // Keep sheet open so user returns to app gracefully
                      // The lifecycle observer will handle permission refresh
                    },
                    child: const Text('Enable'),
                  ),
                ),
              ],
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      );
    },
  );
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
