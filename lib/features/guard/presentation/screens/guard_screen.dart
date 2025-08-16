import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/features/guard/application/first_run_gate.dart';
import 'package:reboot_app_3/features/guard/application/permission_lifecycle.dart';
import 'package:reboot_app_3/features/guard/application/usage_access_provider.dart';
import 'package:reboot_app_3/features/guard/presentation/screens/usage_access_intro_sheet.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/usage_access_banner.dart';
import 'package:reboot_app_3/features/guard/application/ios_lifecycle_observer.dart';
import 'package:reboot_app_3/features/guard/application/ios_focus_providers.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/ios_auth_banner.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/ios_picker_controls.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/real_data_display.dart';

class GuardScreen extends ConsumerWidget {
  const GuardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    // Register lifecycle observer to handle app resume
    ref.watch(permissionLifecycleProvider);

    // Register iOS lifecycle observer to handle Screen Time auth
    ref.watch(iosLifecycleProvider);

    // Check permission status and show intro sheet on first run
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid) {
        final hasSeenIntro = await getHasSeenUsageAccessIntro();
        if (!hasSeenIntro && context.mounted) {
          final usageAccessAsync = ref.read(usageAccessGrantedProvider);
          usageAccessAsync.whenData((isGranted) {
            if (!isGranted && context.mounted) {
              showUsageAccessIntroSheet(context);
            }
          });
        }
      }
      if (Platform.isIOS) {
        final hasSeenIntro = await getHasSeenUsageAccessIntro();
        if (!hasSeenIntro && context.mounted) {
          final usageAccessAsync = ref.read(usageAccessGrantedProvider);
          usageAccessAsync.whenData((isGranted) {
            if (!isGranted && context.mounted) {
              showUsageAccessIntroSheet(context);
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: appBar(context, ref, "guard", false, false),
      backgroundColor: theme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usage Access Permission Banner
            const UsageAccessBanner(),

            // iOS Screen Time Banner
            const IosAuthBanner(),
            const SizedBox(height: 12),

            // iOS Picker Controls
            const IosPickerControls(),
            const SizedBox(height: 16),

            // Real Focus Score Card (muted when permission missing)
            Consumer(
              builder: (context, ref, child) {
                final usageAccessAsync = ref.watch(usageAccessGrantedProvider);

                return usageAccessAsync.when(
                  data: (isGranted) {
                    final heroCard = const RealUsageMetricsCard();

                    if (!isGranted) {
                      // Mute the card when permission is missing
                      return Stack(
                        children: [
                          IgnorePointer(
                            ignoring: true,
                            child: Opacity(
                              opacity: 0.4,
                              child: heroCard,
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                child: Text(
                                  'Permission required',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return heroCard;
                  },
                  loading: () => Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      height: 136,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (_, __) => Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      height: 136,
                      child: const Center(
                        child: Text('Error loading Focus Score'),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Real app usage data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today\'s Top Apps',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    // Refresh data manually
                    ref.invalidate(iosSnapshotProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh data',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: RealAppUsageList(),
            ),

            const SizedBox(height: 24),

            // Weekly Trends placeholder
            const Text('Last 7 Days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('Bar Chart Placeholder'),
            ),
          ],
        ),
      ),
    );
  }
}
