import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'package:reboot_app_3/features/account/application/ban_warning_facade.dart';
import 'package:reboot_app_3/features/account/providers/clean_ban_warning_providers.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class BanDebugScreen extends ConsumerStatefulWidget {
  const BanDebugScreen({super.key});

  @override
  ConsumerState<BanDebugScreen> createState() => _BanDebugScreenState();
}

class _BanDebugScreenState extends ConsumerState<BanDebugScreen> {
  String _debugOutput = 'Tap buttons below to test ban functionality\n\n';
  bool _isLoading = false;

  void _addToOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }

  void _clearOutput() {
    setState(() {
      _debugOutput = 'Debug output cleared\n\n';
    });
  }

  Future<void> _testStartupSecurity() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('=== TESTING STARTUP SECURITY ===');

    try {
      final securityService = StartupSecurityService();
      final result = await securityService.initializeAppSecurity();

      _addToOutput('Security Result: ${result.status}');
      _addToOutput('Message: ${result.message}');
      _addToOutput('Is Blocked: ${result.isBlocked}');
      _addToOutput('Device ID: ${result.deviceId}');
      _addToOutput('User ID: ${result.userId}');
      _addToOutput(
          'Feature Access Map: ${result.featureAccessMap?.length ?? 0} features');
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    _addToOutput('=== END STARTUP SECURITY TEST ===\n');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testUserBanCheck() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('=== TESTING USER BAN CHECK ===');

    try {
      final facade = BanWarningFacade();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _addToOutput('No user logged in');
        return;
      }

      _addToOutput('Current User: ${user.uid}');

      final isBanned = await facade.isCurrentUserBannedFromApp();
      _addToOutput('Is Current User Banned: $isBanned');

      final bans = await facade.getCurrentUserBans();
      _addToOutput('Total Bans Found: ${bans.length}');

      for (int i = 0; i < bans.length; i++) {
        final ban = bans[i];
        _addToOutput(
            'Ban $i: ${ban.id} - ${ban.scope} - Active: ${ban.isActive} - Expired: ${ban.isExpired}');
      }
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    _addToOutput('=== END USER BAN CHECK ===\n');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testProviderBanCheck() async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('=== TESTING PROVIDER BAN CHECK ===');

    try {
      final bansAsync = ref.read(currentUserBansProvider);

      bansAsync.when(
        loading: () => _addToOutput('Provider: Loading...'),
        error: (error, stack) => _addToOutput('Provider Error: $error'),
        data: (bans) {
          _addToOutput('Provider Bans Found: ${bans.length}');
          for (int i = 0; i < bans.length; i++) {
            final ban = bans[i];
            _addToOutput(
                'Provider Ban $i: ${ban.id} - ${ban.scope} - Active: ${ban.isActive}');
          }
        },
      );
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    _addToOutput('=== END PROVIDER BAN CHECK ===\n');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ban Debug Screen'),
        backgroundColor: theme.primary[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testStartupSecurity,
                        child: const Text('Test Startup Security'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testUserBanCheck,
                        child: const Text('Test User Ban Check'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testProviderBanCheck,
                        child: const Text('Test Provider Check'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearOutput,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.error[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear Output'),
                      ),
                    ),
                  ],
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),

          // Debug output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: theme.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugOutput,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
