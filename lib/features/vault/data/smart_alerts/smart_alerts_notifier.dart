import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_service.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_notification_service.dart';
import 'package:reboot_app_3/features/vault/data/repositories/smart_alerts_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:reboot_app_3/core/notifications/notifications_scheduler.dart';

part 'smart_alerts_notifier.g.dart';

@riverpod
SmartAlertsService smartAlertsService(Ref ref) {
  final followUpRepository =
      FollowUpRepository(FirebaseFirestore.instance, ref);
  final smartAlertsRepository = ref.read(smartAlertsRepositoryProvider);
  final subscriptionService =
      SubscriptionService(ref.read(subscriptionRepositoryProvider));

  return SmartAlertsService(
    followUpRepository,
    smartAlertsRepository,
    subscriptionService,
  );
}

@riverpod
SmartAlertsNotificationService smartAlertsNotificationService(Ref ref) {
  final smartAlertsService = ref.read(smartAlertsServiceProvider);
  final smartAlertsRepository = ref.read(smartAlertsRepositoryProvider);
  final notificationsScheduler = NotificationsScheduler.instance;

  return SmartAlertsNotificationService(
    smartAlertsService,
    smartAlertsRepository,
    notificationsScheduler,
  );
}

@riverpod
Stream<SmartAlertSettings?> smartAlertSettings(Ref ref) {
  final repository = ref.read(smartAlertsRepositoryProvider);
  return repository.watchSmartAlertSettings();
}

@riverpod
Future<SmartAlertEligibility> smartAlertEligibility(Ref ref) async {
  final service = ref.read(smartAlertsServiceProvider);
  return await service.checkEligibility();
}

@riverpod
Future<Map<SmartAlertType, DateTime?>> nextAlertTimes(Ref ref) async {
  final notificationService = ref.read(smartAlertsNotificationServiceProvider);
  return await notificationService.getNextAlertTimes();
}

@riverpod
Future<bool> notificationsEnabled(Ref ref) async {
  final notificationService = ref.read(smartAlertsNotificationServiceProvider);
  return await notificationService.areNotificationsEnabled();
}

/// Notifier for managing smart alert settings
@riverpod
class SmartAlertsNotifier extends _$SmartAlertsNotifier {
  @override
  FutureOr<SmartAlertSettings?> build() async {
    final repository = ref.read(smartAlertsRepositoryProvider);
    return await repository.getSmartAlertSettings();
  }

  /// Toggle high-risk hour alert
  Future<void> toggleRiskHourAlert(bool enabled) async {
    final repository = ref.read(smartAlertsRepositoryProvider);
    await repository.updateAlertToggle(SmartAlertType.highRiskHour, enabled);

    // Reschedule alerts
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.rescheduleAlerts();

    // Refresh state
    ref.invalidateSelf();
  }

  /// Toggle vulnerability alert
  Future<void> toggleVulnerabilityAlert(bool enabled) async {
    final repository = ref.read(smartAlertsRepositoryProvider);
    await repository.updateAlertToggle(
        SmartAlertType.streakVulnerability, enabled);

    // Reschedule alerts
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.rescheduleAlerts();

    // Refresh state
    ref.invalidateSelf();
  }

  /// Update vulnerability alert hour
  Future<void> updateVulnerabilityAlertHour(int hour) async {
    final repository = ref.read(smartAlertsRepositoryProvider);
    await repository.updateVulnerabilityAlertHour(hour);

    // Reschedule alerts with new time
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.rescheduleAlerts();

    // Refresh state
    ref.invalidateSelf();
    ref.invalidate(nextAlertTimesProvider);
  }

  /// Calculate and update risk patterns
  Future<void> calculateRiskPatterns() async {
    final service = ref.read(smartAlertsServiceProvider);

    // Calculate risk hour and vulnerable weekday
    await Future.wait([
      service.calculateRiskHour(),
      service.calculateVulnerableWeekday(),
    ]);

    // Reschedule alerts with new data
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.rescheduleAlerts();

    // Refresh state
    ref.invalidateSelf();
    ref.invalidate(smartAlertEligibilityProvider);
    ref.invalidate(nextAlertTimesProvider);
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    final granted = await notificationService.checkAndRequestPermissions();

    if (granted) {
      // Schedule alerts if permissions granted
      await notificationService.scheduleSmartAlerts();
    }

    // Refresh notification status
    ref.invalidate(notificationsEnabledProvider);

    return granted;
  }

  /// Test notification
  Future<void> sendTestNotification(SmartAlertType type) async {
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.showTestNotification(type);
  }

  /// Initialize smart alerts (setup calculations and scheduling)
  Future<void> initializeSmartAlerts() async {
    // Check eligibility first
    final eligibility = await ref.read(smartAlertEligibilityProvider.future);

    if (!eligibility.isEligibleForRiskHour &&
        !eligibility.isEligibleForVulnerability) {
      return; // Not eligible for any alerts
    }

    // Calculate patterns if eligible and not already calculated
    final settings = await ref.read(smartAlertSettingsProvider.future);

    if (settings != null) {
      bool needsCalculation = false;

      if (eligibility.isEligibleForRiskHour &&
          !settings.hasEnoughDataForRiskHour) {
        needsCalculation = true;
      }

      if (eligibility.isEligibleForVulnerability &&
          !settings.hasEnoughDataForVulnerability) {
        needsCalculation = true;
      }

      if (needsCalculation) {
        await calculateRiskPatterns();
      } else {
        // Just reschedule with existing data
        final notificationService =
            ref.read(smartAlertsNotificationServiceProvider);
        await notificationService.scheduleSmartAlerts();
      }
    }
  }

  /// Handle daily recalculation (called by background task)
  Future<void> performDailyRecalculation() async {
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.performDailyRecalculation();

    // Refresh all related providers
    ref.invalidateSelf();
    ref.invalidate(smartAlertEligibilityProvider);
    ref.invalidate(nextAlertTimesProvider);
  }

  /// Disable banner for permission denied
  Future<void> dismissPermissionBanner() async {
    final repository = ref.read(smartAlertsRepositoryProvider);
    await repository.updatePermissionBannerStatus(true);
    ref.invalidateSelf();
  }
}
