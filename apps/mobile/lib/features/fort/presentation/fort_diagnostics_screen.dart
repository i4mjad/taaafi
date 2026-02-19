import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/fort/data/notifiers/fort_state_notifier.dart';
import 'package:reboot_app_3/features/fort/data/notifiers/usage_notifier.dart';
import 'package:reboot_app_3/features/fort/data/services/native_usage_bridge.dart';

/// In-app diagnostics screen for the Fort native bridge.
/// Shows live state, raw native responses, and a scrollable event log.
class FortDiagnosticsScreen extends ConsumerStatefulWidget {
  const FortDiagnosticsScreen({super.key});

  @override
  ConsumerState<FortDiagnosticsScreen> createState() =>
      _FortDiagnosticsScreenState();
}

class _FortDiagnosticsScreenState
    extends ConsumerState<FortDiagnosticsScreen> {
  static const _channel = MethodChannel('com.taaafi.fort');

  final List<_LogEntry> _logs = [];
  final _scrollController = ScrollController();

  void _addLog(String tag, String message, {bool isError = false}) {
    setState(() {
      _logs.add(_LogEntry(
        time: DateTime.now(),
        tag: tag,
        message: message,
        isError: isError,
      ));
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _checkPermission() async {
    _addLog('PERM', 'Checking usage permission...');
    try {
      final bridge = ref.read(nativeUsageBridgeProvider);
      final result = await bridge.checkUsagePermission();
      _addLog('PERM', 'hasPermission = $result');
    } catch (e) {
      _addLog('PERM', 'ERROR: $e', isError: true);
    }
  }

  Future<void> _requestPermission() async {
    _addLog('PERM', 'Requesting usage permission...');
    try {
      final bridge = ref.read(nativeUsageBridgeProvider);
      final result = await bridge.requestUsagePermission();
      _addLog('PERM', 'granted = $result');
    } catch (e) {
      _addLog('PERM', 'ERROR: $e', isError: true);
    }
  }

  Future<void> _fetchUsage() async {
    _addLog('USAGE', 'Fetching today usage...');
    try {
      final bridge = ref.read(nativeUsageBridgeProvider);
      final summary = await bridge.getTodayUsage();
      final json = const JsonEncoder.withIndent('  ').convert(summary.toJson());
      _addLog('USAGE', 'Result:\n$json');
    } catch (e) {
      _addLog('USAGE', 'ERROR: $e', isError: true);
    }
  }

  Future<void> _rawChannelCall(String method) async {
    _addLog('RAW', 'Calling $method...');
    try {
      final result = await _channel.invokeMethod<dynamic>(method);
      if (result is String) {
        // Try to pretty-print JSON
        try {
          final parsed = jsonDecode(result);
          final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
          _addLog('RAW', '$method response:\n$pretty');
        } catch (_) {
          _addLog('RAW', '$method response: $result');
        }
      } else {
        _addLog('RAW', '$method response: $result (${result.runtimeType})');
      }
    } on PlatformException catch (e) {
      _addLog('RAW', '$method PlatformException: ${e.code} — ${e.message}',
          isError: true);
    } on MissingPluginException catch (e) {
      _addLog('RAW', '$method MissingPluginException: ${e.message}',
          isError: true);
    } catch (e) {
      _addLog('RAW', '$method ERROR: $e', isError: true);
    }
  }

  void _copyLogs() {
    final text = _logs.map((l) {
      final time =
          '${l.time.hour.toString().padLeft(2, '0')}:${l.time.minute.toString().padLeft(2, '0')}:${l.time.second.toString().padLeft(2, '0')}';
      return '[$time] [${l.tag}] ${l.message}';
    }).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permAsync = ref.watch(usagePermissionProvider);
    final usageAsync = ref.watch(usageNotifierProvider);
    final fortAsync = ref.watch(fortStateNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? theme.grey[900] : theme.grey[50],
      appBar: AppBar(
        title: const Text('Fort Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _logs.isEmpty ? null : _copyLogs,
            tooltip: 'Copy logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status cards
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? theme.grey[800] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? theme.grey[300] : theme.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                _StatusRow(
                  label: 'Permission',
                  value: permAsync.when(
                    data: (v) => v ? 'GRANTED' : 'DENIED',
                    loading: () => 'loading...',
                    error: (e, _) => 'ERROR: $e',
                  ),
                  color: permAsync.valueOrNull == true
                      ? Colors.green
                      : Colors.orange,
                ),
                _StatusRow(
                  label: 'Usage Data',
                  value: usageAsync.when(
                    data: (s) =>
                        '${s.categories.length} cats, ${s.totalScreenTimeMinutes}min, ${s.pickups} pickups',
                    loading: () => 'loading...',
                    error: (e, _) => 'ERROR: $e',
                  ),
                  color: (usageAsync.valueOrNull?.categories.isNotEmpty ?? false)
                      ? Colors.green
                      : Colors.orange,
                ),
                _StatusRow(
                  label: 'Fort State',
                  value: fortAsync.when(
                    data: (f) => f == null
                        ? 'null (no doc)'
                        : 'Lv${f.level} ${f.xp}/${f.xpForNextLevel}XP',
                    loading: () => 'loading...',
                    error: (e, _) => 'ERROR: $e',
                  ),
                  color: fortAsync.valueOrNull != null
                      ? Colors.green
                      : theme.grey[500]!,
                ),
              ],
            ),
          ),

          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _ActionChip(
                  label: 'Check Perm',
                  onPressed: _checkPermission,
                ),
                _ActionChip(
                  label: 'Request Perm',
                  onPressed: _requestPermission,
                ),
                _ActionChip(
                  label: 'Fetch Usage',
                  onPressed: _fetchUsage,
                ),
                if (Platform.isIOS) ...[
                  _ActionChip(
                    label: 'Raw: checkAuth',
                    onPressed: () =>
                        _rawChannelCall('ios_checkFamilyControlsAuth'),
                  ),
                  _ActionChip(
                    label: 'Raw: getReport',
                    onPressed: () => _rawChannelCall('ios_getUsageReport'),
                  ),
                ],
                if (Platform.isAndroid) ...[
                  _ActionChip(
                    label: 'Raw: checkAccess',
                    onPressed: () =>
                        _rawChannelCall('android_checkUsageAccess'),
                  ),
                  _ActionChip(
                    label: 'Raw: getCategory',
                    onPressed: () =>
                        _rawChannelCall('android_getCategoryUsage'),
                  ),
                ],
                _ActionChip(
                  label: 'Refresh Providers',
                  onPressed: () {
                    _addLog('UI', 'Invalidating all fort providers');
                    ref.invalidate(usagePermissionProvider);
                    ref.invalidate(usageNotifierProvider);
                    ref.invalidate(fortStateNotifierProvider);
                  },
                ),
              ],
            ),
          ),

          // Log output
          Expanded(
            child: Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF1A1A2E),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'Tap buttons above to start diagnostics',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final time =
                            '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SelectableText.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$time ',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                                TextSpan(
                                  text: '[${log.tag}] ',
                                  style: TextStyle(
                                    color: _tagColor(log.tag),
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: log.message,
                                  style: TextStyle(
                                    color: log.isError
                                        ? Colors.redAccent
                                        : Colors.greenAccent[100],
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'PERM':
        return Colors.amber;
      case 'USAGE':
        return Colors.cyan;
      case 'RAW':
        return Colors.purpleAccent;
      case 'UI':
        return Colors.lightBlue;
      default:
        return Colors.white70;
    }
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ActionChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onPressed,
      ),
    );
  }
}

class _LogEntry {
  final DateTime time;
  final String tag;
  final String message;
  final bool isError;

  const _LogEntry({
    required this.time,
    required this.tag,
    required this.message,
    this.isError = false,
  });
}
