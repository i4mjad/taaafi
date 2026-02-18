import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/community/application/notification_service.dart';
import 'package:reboot_app_3/features/community/data/models/notification_preferences.dart';

/// StateNotifier for notification preferences with periodic refresh
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationService _notificationService;
  Timer? _refreshTimer;

  NotificationPreferencesNotifier(this._notificationService)
      : super(const AsyncValue.loading()) {
    _loadInitialPreferences();
    _startPeriodicRefresh();
  }

  Future<void> _loadInitialPreferences() async {
    try {
      state = const AsyncValue.loading();
      final preferences =
          await _notificationService.checkAndUpdateSystemStatus();
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshSystemStatus();
    });
  }

  Future<void> _refreshSystemStatus() async {
    try {
      final preferences =
          await _notificationService.checkAndUpdateSystemStatus();
      state = AsyncValue.data(preferences);
    } catch (e) {
      // Don't update state on error during periodic refresh to avoid flickering
      print('Error during periodic notification status refresh: $e');
    }
  }

  Future<void> updateMessageNotifications(bool value) async {
    final currentState = state;
    if (currentState is! AsyncData<NotificationPreferences>) return;

    try {
      final updatedPreferences = currentState.value.copyWith(
        messagesNotifications: value,
      );

      await _notificationService
          .updateNotificationPreferences(updatedPreferences);

      // Refresh to get updated preferences
      await _refreshSystemStatus();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshPreferences() async {
    await _refreshSystemStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for notification preferences with periodic refresh
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationPreferencesNotifier(notificationService);
});

class GroupNotificationSettingsScreen extends ConsumerStatefulWidget {
  const GroupNotificationSettingsScreen({super.key});

  @override
  ConsumerState<GroupNotificationSettingsScreen> createState() =>
      _GroupNotificationSettingsScreenState();
}

class _GroupNotificationSettingsScreenState
    extends ConsumerState<GroupNotificationSettingsScreen> {
  bool _isLoading = false;

  Future<void> _handleAppNotificationsToggle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final hasPermissions =
          await notificationService.areSystemNotificationsEnabled();

      if (!hasPermissions) {
        // Request permissions or open settings
        final granted =
            await notificationService.requestNotificationPermissions();
        if (!granted) {
          // Open app settings if permission not granted
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
        }
      } else {
        // If notifications are enabled, open settings to disable them
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      }

      // Refresh preferences after returning from settings (will happen automatically via timer)
    } catch (e) {
      print('Error handling app notifications toggle: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMessageNotifications(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updateMessageNotifications(value);
    } catch (e) {
      print('Error updating message notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "notification-settings", false, true),
      body: preferencesAsync.when(
        data: (preferences) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Enable App Notifications
                WidgetsContainer(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: PlatformSwitch(
                    value: preferences.appNotificationsEnabled,
                    onChanged: _isLoading
                        ? null
                        : (_) => _handleAppNotificationsToggle(),
                    label: l10n.translate('enable-notifications'),
                  ),
                ),

                verticalSpace(Spacing.points8),

                // Message Notifications
                WidgetsContainer(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: PlatformSwitch(
                    value: preferences.messagesNotifications,
                    onChanged:
                        (preferences.appNotificationsEnabled && !_isLoading)
                            ? _updateMessageNotifications
                            : null,
                    label: l10n.translate('message-notifications'),
                  ),
                ),

                // Note: Only showing message notifications as requested
                // Challenge and update notifications are hidden for now
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading notification settings: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
