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
import 'package:reboot_app_3/features/guard/presentation/widgets/ios_picker_controls.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/ios_activity_report_view.dart';
import 'package:reboot_app_3/features/guard/presentation/widgets/opal_style_focus_display.dart';
import 'package:reboot_app_3/features/guard/application/ios_focus_providers.dart';
import 'package:reboot_app_3/features/guard/data/guard_usage_repository.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/logging/focus_log.dart';
// Removed unused import: custom_theme_data
import 'package:reboot_app_3/core/theming/text_styles.dart';
// Removed unused import: container

class GuardScreen extends ConsumerWidget {
  const GuardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    focusLog('📱 [GUARD SCREEN] ========================================');
    focusLog('📱 [GUARD SCREEN] === GuardScreen: BUILD START ===');
    focusLog('📱 [GUARD SCREEN] ========================================');

    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // FOR iOS: BLOCK UI RENDERING UNTIL PERMISSION CHECK COMPLETES
    // This prevents the banner from showing incorrectly and ensures
    // we know the actual permission state before rendering content
    if (Platform.isIOS) {
      final authStatusAsync = ref.watch(iosAuthStatusProvider);

      // Show loading state while checking permissions
      return authStatusAsync.when(
        loading: () {
          focusLog('📱 [GUARD SCREEN] ⏳ Checking iOS authorization status...');
          return Scaffold(
            appBar: appBar(context, ref, "guard", false, false),
            backgroundColor: theme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Checking permissions...',
                    style: TextStyles.body.copyWith(color: theme.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
        error: (error, stack) {
          focusLog('📱 [GUARD SCREEN] ❌ Error checking authorization',
              data: error);
          // On error, assume not authorized and continue
          return _buildMainContent(context, ref, theme, localizations, false);
        },
        data: (isAuthorized) {
          focusLog(
              '📱 [GUARD SCREEN] ✅ Authorization check complete: $isAuthorized');
          return _buildMainContent(
              context, ref, theme, localizations, isAuthorized);
        },
      );
    }

    // For non-iOS platforms, render directly
    return _buildMainContent(context, ref, theme, localizations, true);
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    dynamic localizations,
    bool isIosAuthorized,
  ) {
    // Activate guard streams when this screen is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusLog('📱 [GUARD SCREEN] postFrameCallback: activating guard streams');
      if (context.mounted) {
        ref.read(guardStreamActiveProvider.notifier).state = true;
        focusLog(
            '📱 [GUARD SCREEN] postFrameCallback: ✅ guard streams activated');
      }
    });

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
      appBar: appBar(context, ref, "guard", false, false, actions: [
        const IosPickerControls(),
        IconButton(
          tooltip: localizations.translate('view_logs'),
          icon: const Icon(Icons.list_alt),
          onPressed: () async {
            if (!context.mounted) return;
            await showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              showDragHandle: true,
              backgroundColor: AppTheme.of(context).backgroundColor,
              builder: (ctx) {
                final sheetTheme = AppTheme.of(ctx);
                return SafeArea(
                  child: DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.6,
                    minChildSize: 0.3,
                    maxChildSize: 0.95,
                    builder: (context, controller) {
                      return Consumer(
                        builder: (context, ref, _) {
                          final logsAsync = ref.watch(logsStreamProvider);
                          final theme = AppTheme.of(context);
                          return logsAsync.when(
                            data: (logs) => Container(
                              color: sheetTheme.backgroundColor,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Count label for quick debugging/visibility
                                        Text('${logs.length}',
                                            style: TextStyles.caption.copyWith(
                                              color: theme.grey[600],
                                            )),
                                        Row(
                                          children: [
                                            IconButton(
                                              tooltip: localizations
                                                  .translate('refresh_now'),
                                              onPressed: () {
                                                // force re-fetch
                                                ref.invalidate(
                                                    nativeLogsProvider);
                                              },
                                              icon: const Icon(Icons.refresh),
                                            ),
                                            TextButton.icon(
                                              onPressed: () async {
                                                await clearNativeLogs();
                                                ref.invalidate(
                                                    nativeLogsProvider);
                                              },
                                              icon: const Icon(
                                                  Icons.delete_sweep),
                                              label: Text(
                                                localizations
                                                    .translate('clear'),
                                                style: TextStyles.footnote
                                                    .copyWith(
                                                  color: theme.grey[900],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: theme.grey[200]),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: controller,
                                      itemCount: logs.length,
                                      itemBuilder: (context, index) {
                                        final line = logs[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          child: Text(
                                            line,
                                            style: TextStyles.footnote.copyWith(
                                              color: theme.grey[900],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Error: $e',
                                  style: TextStyles.footnote.copyWith(
                                    color: theme.grey[900],
                                  )),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ]),
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Usage Access Permission Banner
              const UsageAccessBanner(),

              // iOS Screen Time Banner (only show if NOT authorized)
              if (Platform.isIOS && !isIosAuthorized) ...[
                MaterialBanner(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.lock_outline),
                  content: const Text(
                      'Screen Time access is required to track app usage on iOS.'),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        focusLog(
                            '🔵 [GUARD SCREEN] Enable Screen Time button tapped');
                        try {
                          await iosRequestAuthorization();
                          focusLog('🔵 [GUARD SCREEN] Authorization requested');
                          // Invalidate to refresh the entire screen with new status
                          ref.invalidate(iosAuthStatusProvider);

                          // Start monitoring if authorized
                          final newStatus = await iosGetAuthorizationStatus();
                          if (newStatus) {
                            focusLog(
                                '🔵 [GUARD SCREEN] Starting monitoring...');
                            await iosStartMonitoring();
                          }
                        } catch (e) {
                          focusLog(
                              '🔵 [GUARD SCREEN] Error requesting authorization',
                              data: e);
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
                ),
                const SizedBox(height: 12),
              ],

              // ========================================
              // HIDDEN: iOS DeviceActivityReport Widget (Data Extraction Trigger)
              // This widget is hidden but ACTIVE to trigger per-app data extraction
              // The native extension processes Screen Time data and saves to App Group
              // Only render if authorized (already checked above)
              // ========================================
              if (Platform.isIOS && isIosAuthorized)
                const SizedBox(
                  height: 0,
                  width: 0,
                  child: IosActivityReportView(),
                ),

              // ========================================
              // COMMENTED OUT: Opal-style Focus Score Card
              // Reason: Focusing on Apps list only
              // ========================================
              // Consumer(
              //   builder: (context, ref, child) {
              //     final usageAccessAsync =
              //         ref.watch(usageAccessGrantedProvider);
              //
              //     return usageAccessAsync.when(
              //       data: (isGranted) {
              //         final heroCard = const OpalFocusScoreCard();
              //
              //         if (!isGranted) {
              //           // Mute the card when permission is missing
              //           return Stack(
              //             children: [
              //               IgnorePointer(
              //                 ignoring: true,
              //                 child: Opacity(
              //                   opacity: 0.4,
              //                   child: heroCard,
              //                 ),
              //               ),
              //               Positioned.fill(
              //                 child: Center(
              //                   child: Container(
              //                     padding: const EdgeInsets.symmetric(
              //                       horizontal: 12,
              //                       vertical: 6,
              //                     ),
              //                     decoration: BoxDecoration(
              //                       color: theme.backgroundColor,
              //                       borderRadius: BorderRadius.circular(20),
              //                       border: Border.all(
              //                         color:
              //                             Theme.of(context).colorScheme.outline,
              //                       ),
              //                     ),
              //                     child: Text(
              //                       localizations
              //                           .translate('usage_access_required'),
              //                       style: TextStyles.caption.copyWith(
              //                         color: theme.grey[600],
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           );
              //         }
              //
              //         return heroCard;
              //       },
              //       loading: () =>
              //           const Center(child: CircularProgressIndicator()),
              //       error: (error, stackTrace) =>
              //           Center(child: Text('Error: $error')),
              //     );
              //   },
              // ),
              // const SizedBox(height: 24),

              // Apps Section with Live indicator (RENAMED from "Top Apps")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apps', // Changed from localizations.translate('top_apps')
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      // Live indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.translate('live'),
                        style: TextStyles.tiny.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // Trigger manual refresh
                          final currentCount = ref.read(manualRefreshProvider);
                          ref.read(manualRefreshProvider.notifier).state =
                              currentCount + 1;
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: localizations.translate('refresh_now'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Beautiful App Usage List
              const OpalAppUsageList(),

              const SizedBox(height: 16),

              // Time Offline Section (Opal-style)
              // _TimeOfflineSection(
              //   theme: theme,
              //   localizations: localizations,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Time Offline section similar to Opal design
// class _TimeOfflineSection extends StatelessWidget {
//   final CustomThemeData theme;
//   final AppLocalizations localizations;
//
//   const _TimeOfflineSection({
//     required this.theme,
//     required this.localizations,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return WidgetsContainer(
//       backgroundColor: theme.backgroundColor,
//       borderRadius: BorderRadius.circular(20),
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           // Offline icon
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: theme.primary[50],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.offline_bolt,
//               color: theme.primary[500],
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//
//           // Time offline info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   localizations.translate('time_offline'),
//                   style: TextStyles.h6.copyWith(
//                     color: theme.grey[900],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '10h 38m', // This would come from actual data
//                   style: TextStyles.h4.copyWith(
//                     color: theme.grey[900],
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '62% ${localizations.translate('of_your_day')}',
//                   style: TextStyles.caption.copyWith(
//                     color: theme.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Block Now button (Opal-style)
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF10B981),
//                   const Color(0xFF34D399),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(24),
//                 onTap: () {
//                   // Block functionality would go here
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.play_arrow,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         localizations.translate('block_now'),
//                         style: TextStyles.footnote.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
