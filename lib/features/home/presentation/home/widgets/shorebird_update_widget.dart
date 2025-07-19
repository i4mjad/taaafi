import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:restart_app/restart_app.dart';

// Provider for managing Shorebird update state
final shorebirdUpdateProvider =
    StateNotifierProvider<ShorebirdUpdateNotifier, ShorebirdUpdateState>((ref) {
  return ShorebirdUpdateNotifier();
});

// Update states
enum AppUpdateStatus {
  checking,
  available,
  downloading,
  completed,
  error,
  none,
}

class ShorebirdUpdateState {
  final AppUpdateStatus status;
  final double downloadProgress;
  final String? error;

  ShorebirdUpdateState({
    required this.status,
    this.downloadProgress = 0.0,
    this.error,
  });

  ShorebirdUpdateState copyWith({
    AppUpdateStatus? status,
    double? downloadProgress,
    String? error,
  }) {
    return ShorebirdUpdateState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
    );
  }
}

class ShorebirdUpdateNotifier extends StateNotifier<ShorebirdUpdateState> {
  final _updater = ShorebirdUpdater();
  Timer? _progressTimer;

  ShorebirdUpdateNotifier()
      : super(ShorebirdUpdateState(status: AppUpdateStatus.none)) {
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(status: AppUpdateStatus.checking);

    try {
      final updateStatus = await _updater.checkForUpdate();

      // Check if update is available using the v2.0+ API
      if (updateStatus == UpdateStatus.outdated) {
        state = state.copyWith(status: AppUpdateStatus.available);
      } else {
        state = state.copyWith(status: AppUpdateStatus.none);
      }
    } catch (e) {
      state =
          state.copyWith(status: AppUpdateStatus.error, error: e.toString());
    }
  }

  Future<void> downloadUpdate() async {
    state = state.copyWith(
        status: AppUpdateStatus.downloading, downloadProgress: 0.0);

    // Start progress simulation timer
    _startProgressTimer();

    try {
      // Download and install the update
      await _updater.update();

      // Cancel timer if update completes before simulation
      _progressTimer?.cancel();

      state = state.copyWith(
          status: AppUpdateStatus.completed, downloadProgress: 100.0);
    } catch (e) {
      _progressTimer?.cancel();
      state =
          state.copyWith(status: AppUpdateStatus.error, error: e.toString());
    }
  }

  void _startProgressTimer() {
    const totalDuration = Duration(seconds: 15); // Estimated download time
    const updateInterval = Duration(milliseconds: 200);
    final totalSteps =
        totalDuration.inMilliseconds / updateInterval.inMilliseconds;
    var currentStep = 0;

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      currentStep++;
      final progress = (currentStep / totalSteps * 100).clamp(0.0, 95.0);

      if (mounted) {
        state = state.copyWith(downloadProgress: progress);
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  void restartApp(BuildContext context) {
    Restart.restartApp(
      /// In Web Platform, Fill webOrigin only when your new origin is different than the app's origin
      // webOrigin: 'http://example.com',

      // Customizing the restart notification message (only needed on iOS)
      notificationTitle: AppLocalizations.of(context)
          .translate('restarting-app-notification-title'),
      notificationBody: AppLocalizations.of(context)
          .translate('restarting-app-notification-body'),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}

class ShorebirdUpdateWidget extends ConsumerWidget {
  const ShorebirdUpdateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(shorebirdUpdateProvider);
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    // Only show widget if update is available, downloading, or completed
    if (updateState.status == AppUpdateStatus.none ||
        updateState.status == AppUpdateStatus.checking) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.primary[50],
        borderSide: BorderSide(color: theme.primary[200]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(context, ref, updateState, theme, localization),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ShorebirdUpdateState state,
    CustomThemeData theme,
    AppLocalizations localization,
  ) {
    switch (state.status) {
      case AppUpdateStatus.available:
        return _buildUpdateAvailable(context, ref, theme, localization);
      case AppUpdateStatus.downloading:
        return _buildDownloading(context, state, theme, localization);
      case AppUpdateStatus.completed:
        return _buildCompleted(context, ref, theme, localization);
      case AppUpdateStatus.error:
        return _buildError(context, theme, localization, state.error);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUpdateAvailable(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations localization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.download,
              size: 24,
              color: theme.primary[600],
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: Text(
                localization.translate('update-available'),
                style: TextStyles.h6.copyWith(
                  color: theme.primary[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Text(
          localization.translate('update-available-message'),
          style: TextStyles.small.copyWith(
            color: theme.primary[800],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(shorebirdUpdateProvider.notifier).downloadUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localization.translate('update-button'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloading(
    BuildContext context,
    ShorebirdUpdateState state,
    CustomThemeData theme,
    AppLocalizations localization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Spinner(
                strokeWidth: 2,
              ),
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: Text(
                localization.translate('updating'),
                style: TextStyles.h6.copyWith(
                  color: theme.primary[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: state.downloadProgress / 100,
            minHeight: 8,
            backgroundColor: theme.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary[600]!),
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          localization.translate('update-download-progress').replaceAll(
              '{percentage}', state.downloadProgress.toStringAsFixed(0)),
          style: TextStyles.small.copyWith(
            color: theme.primary[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations localization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 24,
              color: theme.success[600],
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: Text(
                localization.translate('update-complete'),
                style: TextStyles.h6.copyWith(
                  color: theme.success[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Text(
          localization.translate('update-complete-message'),
          style: TextStyles.small.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(shorebirdUpdateProvider.notifier).restartApp(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.success[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.refreshCw, size: 18),
                horizontalSpace(Spacing.points8),
                Text(
                  localization.translate('restart-app'),
                  style: TextStyles.footnote.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localization,
    String? error,
  ) {
    return Row(
      children: [
        Icon(
          LucideIcons.alertCircle,
          size: 20,
          color: theme.error[600],
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          child: Text(
            error ?? localization.translate('something-went-wrong'),
            style: TextStyles.small.copyWith(
              color: theme.error[700],
            ),
          ),
        ),
      ],
    );
  }
}
