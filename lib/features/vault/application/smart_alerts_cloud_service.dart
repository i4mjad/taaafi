import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service to communicate with Firebase Cloud Functions for Smart Alerts
class SmartAlertsCloudService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's locale
  String _getUserLocale(BuildContext? context) {
    try {
      if (context != null) {
        final locale = Localizations.localeOf(context);
        return locale.languageCode;
      }
      // Fallback to system locale or default
      return WidgetsBinding.instance.window.locale.languageCode;
    } catch (e) {
      // Default fallback
      return 'en';
    }
  }

  /// Trigger a manual smart alerts check for the current user
  /// This calls the Cloud Function to analyze the user's data and send alerts if needed
  Future<SmartAlertsCheckResult> triggerSmartAlertsCheck(
      {BuildContext? context}) async {
    try {
      print('🎯 Triggering smart alerts check via Cloud Function...');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final locale = _getUserLocale(context);
      print('🌐 User locale: $locale');

      final callable = _functions.httpsCallable('triggerSmartAlertsCheck');
      final result = await callable.call({
        'locale': locale,
      });

      final data = result.data as Map<String, dynamic>;

      print('✅ Smart alerts check completed: ${data['message']}');

      return SmartAlertsCheckResult(
        success: data['success'] ?? false,
        alertsSent: data['alertsSent'] ?? 0,
        message: data['message'] ?? 'Unknown result',
        locale: data['locale'] ?? locale,
        alertsAnalyzed: data['alertsAnalyzed'],
      );
    } catch (e) {
      print('❌ Error triggering smart alerts check: $e');
      rethrow;
    }
  }

  /// Send a test smart alert notification
  /// This calls the Cloud Function to send a test notification via FCM
  Future<TestNotificationResult> sendTestNotification(
    SmartAlertType alertType, {
    BuildContext? context,
  }) async {
    try {
      print('🧪 Sending test notification via Cloud Function...');
      print('📱 Alert type: ${alertType.name}');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final locale = _getUserLocale(context);
      print('🌐 User locale: $locale');

      final callable = _functions.httpsCallable('sendTestSmartAlert');
      final result = await callable.call({
        'alertType': alertType.name,
        'locale': locale,
      });

      final data = result.data as Map<String, dynamic>;

      print('✅ Test notification sent: ${data['message']}');

      return TestNotificationResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown result',
        testMessage: data['testMessage'] ?? '',
        alertTypeName: data['alertTypeName'] ?? alertType.name,
        locale: data['locale'] ?? locale,
        fcmStatus: data['fcmStatus'],
        fcmSent: data['fcmSent'],
      );
    } catch (e) {
      print('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// Check if the Cloud Functions are available and responding
  Future<bool> checkCloudFunctionsHealth({BuildContext? context}) async {
    try {
      print('🔍 Checking Cloud Functions health...');

      // Try to call a simple function to test connectivity
      await triggerSmartAlertsCheck(context: context);

      print('✅ Cloud Functions are healthy');
      return true;
    } catch (e) {
      print('⚠️ Cloud Functions health check failed: $e');
      return false;
    }
  }
}

/// Smart Alert types (matching Cloud Function enum)
enum SmartAlertType {
  highRiskHour,
  streakVulnerability,
}

/// Result from triggerSmartAlertsCheck Cloud Function
class SmartAlertsCheckResult {
  final bool success;
  final int alertsSent;
  final String message;
  final String locale;
  final int? alertsAnalyzed;

  const SmartAlertsCheckResult({
    required this.success,
    required this.alertsSent,
    required this.message,
    required this.locale,
    this.alertsAnalyzed,
  });

  @override
  String toString() {
    return 'SmartAlertsCheckResult(success: $success, alertsSent: $alertsSent, message: $message, locale: $locale, alertsAnalyzed: $alertsAnalyzed)';
  }
}

/// Result from sendTestSmartAlert Cloud Function
class TestNotificationResult {
  final bool success;
  final String message;
  final String testMessage;
  final String alertTypeName;
  final String locale;
  final String? fcmStatus;
  final bool? fcmSent;

  const TestNotificationResult({
    required this.success,
    required this.message,
    required this.testMessage,
    required this.alertTypeName,
    required this.locale,
    this.fcmStatus,
    this.fcmSent,
  });

  @override
  String toString() {
    return 'TestNotificationResult(success: $success, message: $message, testMessage: $testMessage, alertTypeName: $alertTypeName, locale: $locale, fcmStatus: $fcmStatus, fcmSent: $fcmSent)';
  }
}
