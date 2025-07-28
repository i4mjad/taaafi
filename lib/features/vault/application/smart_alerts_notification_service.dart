import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_service.dart';
import 'package:reboot_app_3/features/vault/data/repositories/smart_alerts_repository.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';
import 'package:reboot_app_3/core/notifications/notifications_scheduler.dart';

class SmartAlertsNotificationService {
  final SmartAlertsService _smartAlertsService;
  final SmartAlertsRepository _smartAlertsRepository;
  final NotificationsScheduler _notificationsScheduler;

  // Notification IDs for smart alerts
  static const int _riskHourNotificationId = 9001;
  static const int _vulnerabilityNotificationId = 9002;

  // Local notifications instance
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Smart Alerts notification channel
  static const AndroidNotificationChannel _smartAlertsChannel =
      AndroidNotificationChannel(
    'smart_alerts_channel',
    'Smart Alerts',
    description: 'Intelligent relapse prevention alerts',
    importance: Importance.high,
  );

  SmartAlertsNotificationService(
    this._smartAlertsService,
    this._smartAlertsRepository,
    this._notificationsScheduler,
  ) {
    _initializeTimezone();
    _initializeNotificationChannel();
  }

  /// Initialize timezone data for proper scheduling
  void _initializeTimezone() {
    tz_data.initializeTimeZones();
  }

  /// Initialize Smart Alerts notification channel
  Future<void> _initializeNotificationChannel() async {
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_smartAlertsChannel);
    } catch (e) {
      // Channel creation failed, continue with default channel
    }
  }

  /// Schedule timezone-aware notification for Smart Alerts
  Future<void> _scheduleSmartAlert({
    required int notificationId,
    required String title,
    required String body,
    required String payload,
    required DateTime scheduledDate,
  }) async {
    try {
      // Convert to timezone-aware datetime
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _smartAlertsChannel.id,
            _smartAlertsChannel.name,
            channelDescription: _smartAlertsChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Fallback to NotificationsScheduler if direct scheduling fails
      await _notificationsScheduler.showScheduleNotification(
        notificationId: notificationId,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Check and request notification permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      // Check if notifications are enabled
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      if (result == true) {
        return true;
      }

      // For iOS, we need to request permission
      final bool? iosResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      if (iosResult == true) {
        return true;
      }

      // For Android 13+, request notification permission
      final bool? androidResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      return androidResult ?? result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Schedule smart alerts based on current settings and eligibility
  Future<void> scheduleSmartAlerts() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      await _smartAlertsRepository.updatePermissionBannerStatus(true);
      return;
    }

    final settings = await _smartAlertsRepository.getSmartAlertSettings();
    if (settings == null) return;

    final eligibility = await _smartAlertsService.checkEligibility();

    // Schedule high-risk hour alert
    if (settings.isHighRiskHourEnabled &&
        eligibility.isEligibleForRiskHour &&
        settings.hasEnoughDataForRiskHour) {
      await _scheduleRiskHourAlert(settings);
    }

    // Schedule vulnerability alert
    if (settings.isStreakVulnerabilityEnabled &&
        eligibility.isEligibleForVulnerability &&
        settings.hasEnoughDataForVulnerability) {
      await _scheduleVulnerabilityAlert(settings);
    }
  }

  /// Schedule high-risk hour alert (30 minutes before risk hour)
  Future<void> _scheduleRiskHourAlert(SmartAlertSettings settings) async {
    if (settings.lastCalculatedRiskHour == null) return;

    final riskHour = settings.lastCalculatedRiskHour!;
    final alertTime = _smartAlertsService.getNextRiskHourAlertTime(riskHour);

    if (alertTime == null) return;

    // Check if user already relapsed before alert time
    final hasRelapsed =
        await _smartAlertsService.hasRelapsedBeforeAlert(alertTime);
    if (hasRelapsed) {
      // Cancel alert if user already relapsed
      await _cancelRiskHourAlert();
      return;
    }

    // Check daily limit
    if (!settings.canSendAlertToday()) return;

    // Generate alert message
    final message = _smartAlertsService.generateAlertMessage(
      SmartAlertType.highRiskHour,
      hour: riskHour,
    );

    // Schedule the notification with timezone awareness
    await _scheduleSmartAlert(
      notificationId: _riskHourNotificationId,
      title: 'Ta\'aafi Alert',
      body: message,
      payload: 'smart_alert_risk_hour',
      scheduledDate: alertTime,
    );

    // Mark alert as scheduled
    await _smartAlertsRepository.markAlertSent(SmartAlertType.highRiskHour);
  }

  /// Schedule vulnerability alert (8 AM on vulnerable weekday)
  Future<void> _scheduleVulnerabilityAlert(SmartAlertSettings settings) async {
    if (settings.lastCalculatedVulnerableWeekday == null) return;

    final vulnerableWeekday = settings.lastCalculatedVulnerableWeekday!;
    final alertTime = _smartAlertsService.getNextVulnerabilityAlertTime(
        vulnerableWeekday, settings.vulnerabilityAlertHour);

    if (alertTime == null) return;

    // Check if this would conflict with risk hour alert
    final riskHourAlertTime = settings.lastCalculatedRiskHour != null
        ? _smartAlertsService
            .getNextRiskHourAlertTime(settings.lastCalculatedRiskHour!)
        : null;

    if (riskHourAlertTime != null &&
        _smartAlertsService.wouldAlertsConflict(alertTime, riskHourAlertTime)) {
      // Risk hour alert has priority, skip vulnerability alert
      return;
    }

    // Check daily limit
    if (!settings.canSendAlertToday()) return;

    // Check if user relapsed today (for message customization)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final hasRelapsedToday =
        await _smartAlertsService.hasRelapsedBeforeAlert(now);

    // Check if had clean week last time
    final lastWeek = now.subtract(const Duration(days: 7));
    final lastWeekSameDay =
        DateTime(lastWeek.year, lastWeek.month, lastWeek.day, 23, 59, 59);
    final hadCleanWeek =
        !await _smartAlertsService.hasRelapsedBeforeAlert(lastWeekSameDay);

    // Generate alert message
    final message = _smartAlertsService.generateAlertMessage(
      SmartAlertType.streakVulnerability,
      weekday: vulnerableWeekday,
      hasRelapsedToday: hasRelapsedToday,
      hadCleanWeek: hadCleanWeek,
    );

    // Schedule the notification with timezone awareness
    await _scheduleSmartAlert(
      notificationId: _vulnerabilityNotificationId,
      title: 'Ta\'aafi Weekly Check-in',
      body: message,
      payload: 'smart_alert_vulnerability',
      scheduledDate: alertTime,
    );

    // Mark alert as scheduled
    await _smartAlertsRepository
        .markAlertSent(SmartAlertType.streakVulnerability);
  }

  /// Cancel risk hour alert
  Future<void> _cancelRiskHourAlert() async {
    await _localNotifications.cancel(_riskHourNotificationId);
  }

  /// Cancel vulnerability alert
  Future<void> _cancelVulnerabilityAlert() async {
    await _localNotifications.cancel(_vulnerabilityNotificationId);
  }

  /// Cancel all smart alerts
  Future<void> cancelAllSmartAlerts() async {
    await _cancelRiskHourAlert();
    await _cancelVulnerabilityAlert();
  }

  /// Reschedule alerts after settings change
  Future<void> rescheduleAlerts() async {
    await cancelAllSmartAlerts();
    await scheduleSmartAlerts();
  }

  /// Handle daily recalculation of risk patterns (called at 3 AM)
  Future<void> performDailyRecalculation() async {
    final eligibility = await _smartAlertsService.checkEligibility();

    // Recalculate risk hour if eligible
    if (eligibility.isEligibleForRiskHour) {
      await _smartAlertsService.calculateRiskHour();
    }

    // Recalculate vulnerable weekday if eligible
    if (eligibility.isEligibleForVulnerability) {
      await _smartAlertsService.calculateVulnerableWeekday();
    }

    // Reschedule alerts with new calculations
    await rescheduleAlerts();
  }

  /// Handle timezone changes
  Future<void> handleTimezoneChange() async {
    // Cancel existing alerts
    await cancelAllSmartAlerts();

    // Reschedule with new timezone
    await scheduleSmartAlerts();
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification(SmartAlertType type) async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    String title;
    String message;

    switch (type) {
      case SmartAlertType.highRiskHour:
        title = 'Ta\'aafi Alert (Test)';
        message =
            '🛡️ Heads-up! Your high-risk hour starts at 10 PM. Plan a healthy distraction now.';
        break;
      case SmartAlertType.streakVulnerability:
        title = 'Ta\'aafi Weekly Check-in (Test)';
        message =
            '☀️ Good morning! Mondays are your toughest day. Plan an evening walk or check in with your group.';
        break;
    }

    // Show immediate test notification
    await _localNotifications.show(
      999, // Test notification ID
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _smartAlertsChannel.id,
          _smartAlertsChannel.name,
          channelDescription: _smartAlertsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'smart_alert_test_${type.name}',
    );
  }

  /// Get next scheduled alert times for display
  Future<Map<SmartAlertType, DateTime?>> getNextAlertTimes() async {
    final settings = await _smartAlertsRepository.getSmartAlertSettings();
    if (settings == null) return {};

    final result = <SmartAlertType, DateTime?>{};

    if (settings.lastCalculatedRiskHour != null) {
      result[SmartAlertType.highRiskHour] = _smartAlertsService
          .getNextRiskHourAlertTime(settings.lastCalculatedRiskHour!);
    }

    if (settings.lastCalculatedVulnerableWeekday != null) {
      result[SmartAlertType.streakVulnerability] =
          _smartAlertsService.getNextVulnerabilityAlertTime(
              settings.lastCalculatedVulnerableWeekday!,
              settings.vulnerabilityAlertHour);
    }

    return result;
  }

  /// Check if notifications are currently enabled at system level
  Future<bool> areNotificationsEnabled() async {
    try {
      // Check Android notifications
      final bool? androidResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      // For iOS, we can't check without requesting, so assume true if no error
      if (androidResult != null) {
        return androidResult;
      }

      // Fallback: try to check permissions without requesting
      return true; // Conservative approach for iOS
    } catch (e) {
      return false;
    }
  }

  /// Open system notification settings
  Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      // If opening settings fails, try general app settings
      try {
        await AppSettings.openAppSettings();
      } catch (e) {
        // Silently fail if both attempts fail
      }
    }
  }
}
