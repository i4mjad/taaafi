import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/features/vault/application/smart_alerts_cloud_service.dart';

class ManualNotificationTest extends StatelessWidget {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final SmartAlertsCloudService _smartAlertsService =
      SmartAlertsCloudService();

  const ManualNotificationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Notification Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _testBasicNotification(),
              child: Text('Test Basic Notification'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testWithChannel(),
              child: Text('Test With Channel'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkStatus(),
              child: Text('Check Status'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testFCMStyle(),
              child: Text('Test FCM Style'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testVeryBasic(),
              child: Text('Test Very Basic'),
            ),
            SizedBox(height: 30),
            Divider(),
            Text('🧠 Smart Alerts Cloud Functions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testSmartAlertsCheck(context),
              child: Text('🎯 Test Smart Alerts Check'),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _testHighRiskAlert(context),
              child: Text('⚠️ Test High-Risk Alert'),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _testStreakVulnerabilityAlert(context),
              child: Text('🔔 Test Streak Vulnerability Alert'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _testSmartAlertsCheck(BuildContext context) async {
    try {
      print('🎯 Testing Smart Alerts Check...');

      final result =
          await _smartAlertsService.triggerSmartAlertsCheck(context: context);

      print('✅ Smart Alerts Check Result:');
      print('   Success: ${result.success}');
      print('   Message: ${result.message}');
      print('   Alerts Sent: ${result.alertsSent}');
      print('   Locale: ${result.locale}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Smart Alerts Check: ${result.message}')),
        );
      }
    } catch (e) {
      print('❌ Smart Alerts Check failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Smart Alerts Check failed: $e')),
        );
      }
    }
  }

  static Future<void> _testHighRiskAlert(BuildContext context) async {
    try {
      print('⚠️ Testing High-Risk Hour Alert...');

      final result = await _smartAlertsService.sendTestNotification(
        SmartAlertType.highRiskHour,
        context: context,
      );

      print('✅ High-Risk Alert Result:');
      print('   Success: ${result.success}');
      print('   Message: ${result.message}');
      print('   Test Message: ${result.testMessage}');
      print('   Alert Type: ${result.alertTypeName}');
      print('   Locale: ${result.locale}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('High-Risk Alert: ${result.message}')),
        );
      }
    } catch (e) {
      print('❌ High-Risk Alert failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('High-Risk Alert failed: $e')),
        );
      }
    }
  }

  static Future<void> _testStreakVulnerabilityAlert(
      BuildContext context) async {
    try {
      print('🔔 Testing Streak Vulnerability Alert...');

      final result = await _smartAlertsService.sendTestNotification(
        SmartAlertType.streakVulnerability,
        context: context,
      );

      print('✅ Streak Vulnerability Alert Result:');
      print('   Success: ${result.success}');
      print('   Message: ${result.message}');
      print('   Test Message: ${result.testMessage}');
      print('   Alert Type: ${result.alertTypeName}');
      print('   Locale: ${result.locale}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Streak Alert: ${result.message}')),
        );
      }
    } catch (e) {
      print('❌ Streak Vulnerability Alert failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Streak Vulnerability Alert failed: $e')),
        );
      }
    }
  }

  static Future<void> _testBasicNotification() async {
    print('🧪 Testing basic notification...');

    try {
      await _notifications.show(
        123,
        'Basic Test',
        'This is a basic test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test',
            'Test',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('✅ Basic notification sent');
    } catch (e) {
      print('❌ Basic notification failed: $e');
    }
  }

  static Future<void> _testWithChannel() async {
    print('🧪 Testing with channel...');

    try {
      // Create channel first
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'manual_test',
              'Manual Test',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

      await _notifications.show(
        124,
        'Channel Test 🔔',
        'This is a test with proper channel setup',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'manual_test',
            'Manual Test',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Channel notification sent');
    } catch (e) {
      print('❌ Channel notification failed: $e');
    }
  }

  static Future<void> _checkStatus() async {
    print('🔍 Checking notification status...');

    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        print('📱 Notifications enabled: $enabled');

        try {
          final active = await androidPlugin.getActiveNotifications();
          print('📊 Active notifications: ${active.length}');
          for (final n in active) {
            print('   - ID: ${n.id}, Title: ${n.title}');
          }
        } catch (e) {
          print('   Could not get active notifications: $e');
        }
      }
    } catch (e) {
      print('❌ Status check failed: $e');
    }
  }

  static Future<void> _testFCMStyle() async {
    print('🧪 Testing FCM-style notification...');

    try {
      // Use exact same approach as working FCM service
      await _notifications.show(
        555,
        'FCM-Style Test 📬',
        'This notification uses the exact same configuration as FCM!',
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
        payload: 'fcm_style_manual_test',
      );
      print('✅ FCM-style notification sent');
    } catch (e) {
      print('❌ FCM-style notification failed: $e');
    }
  }

  static Future<void> _testVeryBasic() async {
    print('🧪 Testing very basic notification (no channel setup)...');

    try {
      // Most basic notification possible
      await _notifications.show(
        333,
        'Basic Test',
        'Most basic notification possible',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default',
            'Default',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('✅ Very basic notification sent');
    } catch (e) {
      print('❌ Very basic notification failed: $e');
    }
  }
}

// Usage: Add this to your Smart Alerts screen temporarily
/*
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ManualNotificationTest()),
  ),
  child: Text('Manual Test'),
)
*/
