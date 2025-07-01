import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:reboot_app_3/core/messaging/services/fcm_service.dart';

/// Test screen for developers to test notification navigation
/// This screen should only be accessible in debug mode
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoading = true);
    final token = await MessagingService.printFCMToken();
    setState(() {
      _fcmToken = token;
      _isLoading = false;
    });
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FCM Token',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Text(
                          _fcmToken ?? 'No token available',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _copyToken,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Token'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _loadFCMToken,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              'Test Notification Payloads',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these example payloads with Firebase Console or FCM API:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPayloadExample(
                    'Report Conversation',
                    {
                      'screen': 'reportConversation',
                      'reportId': 'test123',
                      'type': 'report_update',
                    },
                  ),
                  _buildPayloadExample(
                    'User Reports',
                    {
                      'screen': 'userReports',
                      'type': 'reports_update',
                    },
                  ),
                  _buildPayloadExample(
                    'Activities',
                    {
                      'screen': 'activities',
                      'type': 'activity_reminder',
                    },
                  ),
                  _buildPayloadExample(
                    'Foreground Navigation',
                    {
                      'screen': 'reportConversation',
                      'reportId': 'urgent123',
                      'navigateInForeground': 'true',
                      'type': 'urgent_report',
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadExample(String title, Map<String, String> data) {
    final payload = {
      'notification': {
        'title': 'Test: $title',
        'body': 'Tap to navigate to $title',
      },
      'data': data,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  _formatJson(payload),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _formatJson(payload)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title payload copied to clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Payload'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
