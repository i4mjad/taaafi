import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_service.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_notification_service.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_cloud_service.dart'
    as cloud;
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

    // Reschedule alerts
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.rescheduleAlerts();

    // Refresh state
    ref.invalidateSelf();
  }

  /// Calculate risk patterns
  Future<void> calculateRiskPatterns() async {
    final service = ref.read(smartAlertsServiceProvider);

    // Calculate risk hour and vulnerable weekday
    await Future.wait([
      service.calculateRiskHour(),
      service.calculateVulnerableWeekday(),
    ]);

    // Schedule alerts with new patterns
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    await notificationService.scheduleSmartAlerts();

    // Refresh state
    ref.invalidateSelf();
    ref.invalidate(smartAlertEligibilityProvider);
    ref.invalidate(nextAlertTimesProvider);
  }

  /// Send test notification (local)
  Future<void> sendTestNotification(SmartAlertType alertType) async {
    final notificationService =
        ref.read(smartAlertsNotificationServiceProvider);
    // Use a simple test approach for now - we can enhance this later
    await notificationService.showSimpleTestNotification();
  }

  /// Send FCM-style test notification using flutter_local_notifications
  /// This tests the same configuration used by Firebase Cloud Messaging
  Future<void> sendFCMStyleTestNotification() async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin.show(
        999,
        'FCM-Style Test 📬',
        'This notification uses the exact same configuration as Firebase Cloud Messaging!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'fcm_style_test',
      );
      print('✅ FCM-style notification sent successfully');
    } catch (e) {
      print('❌ FCM-style test failed: $e');
    }
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

  /// Send test notification via Cloud Functions (NEW FCM APPROACH)
  Future<cloud.TestNotificationResult> sendTestNotificationViaCloud(
    SmartAlertType alertType, {
    BuildContext? context,
  }) async {
    try {
      final cloudService = cloud.SmartAlertsCloudService();

      // Convert local SmartAlertType to cloud SmartAlertType
      final cloudAlertType = alertType == SmartAlertType.highRiskHour
          ? cloud.SmartAlertType.highRiskHour
          : cloud.SmartAlertType.streakVulnerability;

      final result = await cloudService.sendTestNotification(
        cloudAlertType,
        context: context,
      );

      print('✅ Cloud Functions test result: ${result.message}');
      print('📱 FCM Status: ${result.fcmStatus}');
      print('🌐 Locale: ${result.locale}');
      print('🔔 Alert Type: ${result.alertTypeName}');

      return result;
    } catch (e) {
      print('❌ Cloud Functions test failed: $e');
      rethrow;
    }
  }

  /// Trigger smart alerts check via Cloud Functions
  Future<cloud.SmartAlertsCheckResult> triggerCloudAlertsCheck({
    BuildContext? context,
  }) async {
    try {
      final cloudService = cloud.SmartAlertsCloudService();
      final result = await cloudService.triggerSmartAlertsCheck(
        context: context,
      );

      print('✅ Cloud alerts check result: ${result.message}');
      print('📊 Alerts sent: ${result.alertsSent}');
      print('🌐 Locale: ${result.locale}');

      // If this was a manual check, refresh the data
      ref.invalidateSelf();
      ref.invalidate(nextAlertTimesProvider);

      return result;
    } catch (e) {
      print('❌ Cloud alerts check failed: $e');
      rethrow;
    }
  }

  /// Manual smart alerts check - triggers immediate analysis and sends alerts if needed
  Future<cloud.SmartAlertsCheckResult> performManualSmartAlertsCheck({
    BuildContext? context,
  }) async {
    try {
      print('🎯 Performing manual smart alerts check...');

      final result = await triggerCloudAlertsCheck(context: context);

      print('✅ Manual check completed');
      print('   - Message: ${result.message}');
      print('   - Alerts sent: ${result.alertsSent}');
      print('   - Alerts analyzed: ${result.alertsAnalyzed ?? 0}');

      return result;
    } catch (e) {
      print('❌ Manual smart alerts check failed: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Request permissions for iOS
    final iosResult = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android (13+)
    final androidResult = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Refresh notifications enabled state
    ref.invalidate(notificationsEnabledProvider);

    return iosResult ?? androidResult ?? true;
  }
}
