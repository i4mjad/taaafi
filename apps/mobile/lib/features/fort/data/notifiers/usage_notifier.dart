import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/fort/data/repositories/usage_repository.dart';
import 'package:reboot_app_3/features/fort/data/services/native_usage_bridge.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usage_notifier.g.dart';

void _log(String message, [Object? data]) {
  final msg = data != null ? '[Fort Usage] $message: $data' : '[Fort Usage] $message';
  developer.log(msg, name: 'fort');
  // ignore: avoid_print
  print(msg);
}

/// Whether the user has granted usage access permission.
@riverpod
class UsagePermission extends _$UsagePermission {
  @override
  FutureOr<bool> build() async {
    _log('UsagePermission.build → checking permission');
    final bridge = ref.read(nativeUsageBridgeProvider);
    final result = await bridge.checkUsagePermission();
    _log('UsagePermission.build ← result', result);
    return result;
  }

  Future<bool> requestPermission() async {
    _log('UsagePermission.requestPermission → requesting');
    state = const AsyncValue.loading();
    final bridge = ref.read(nativeUsageBridgeProvider);
    final granted = await bridge.requestUsagePermission();
    _log('UsagePermission.requestPermission ← granted', granted);
    state = AsyncValue.data(granted);
    return granted;
  }

  Future<void> recheck() async {
    _log('UsagePermission.recheck → rechecking');
    final bridge = ref.read(nativeUsageBridgeProvider);
    final granted = await bridge.checkUsagePermission();
    _log('UsagePermission.recheck ← granted', granted);
    state = AsyncValue.data(granted);
  }
}

/// Today's usage data — fetches from native and persists to Firestore.
@riverpod
class UsageNotifier extends _$UsageNotifier {
  @override
  FutureOr<UsageSummary> build() async {
    _log('UsageNotifier.build → starting');

    // Wait for user doc to be ready
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    if (userDocAsync.isLoading) {
      _log('UsageNotifier.build ← user doc loading, returning empty');
      return UsageSummary.empty(DateTime.now());
    }
    if (userDocAsync.hasError) {
      _log('UsageNotifier.build ← user doc error', userDocAsync.error);
      return UsageSummary.empty(DateTime.now());
    }
    if (userDocAsync.value == null) {
      _log('UsageNotifier.build ← user doc null, returning empty');
      return UsageSummary.empty(DateTime.now());
    }

    final accountStatus = ref.watch(accountStatusProvider);
    _log('UsageNotifier.build → accountStatus', accountStatus);
    if (accountStatus != AccountStatus.ok) {
      _log('UsageNotifier.build ← account not ok, returning empty');
      return UsageSummary.empty(DateTime.now());
    }

    // Check permission first
    final bridge = ref.read(nativeUsageBridgeProvider);
    final hasPermission = await bridge.checkUsagePermission();
    _log('UsageNotifier.build → hasPermission', hasPermission);
    if (!hasPermission) {
      _log('UsageNotifier.build ← no permission, returning empty');
      return UsageSummary.empty(DateTime.now());
    }

    // Start iOS monitoring (schedules threshold events via DeviceActivityMonitor)
    await bridge.startIosMonitoring();

    // Fetch fresh data from native
    _log('UsageNotifier.build → fetching native usage');
    final summary = await bridge.getTodayUsage();
    _log('UsageNotifier.build ← got summary: categories=${summary.categories.length}, total=${summary.totalScreenTimeMinutes}min');

    // Persist to Firestore in the background
    if (summary.categories.isNotEmpty) {
      _log('UsageNotifier.build → saving to Firestore');
      final repo = ref.read(usageRepositoryProvider);
      repo.saveUsageSummary(summary);
    }

    return summary;
  }

  /// Refresh usage data from native platform.
  Future<void> refresh() async {
    _log('UsageNotifier.refresh → starting');
    state = const AsyncValue.loading();
    try {
      final bridge = ref.read(nativeUsageBridgeProvider);
      final summary = await bridge.getTodayUsage();
      _log('UsageNotifier.refresh ← got summary: categories=${summary.categories.length}');

      if (summary.categories.isNotEmpty) {
        final repo = ref.read(usageRepositoryProvider);
        repo.saveUsageSummary(summary);
      }

      state = AsyncValue.data(summary);
    } catch (e, st) {
      _log('UsageNotifier.refresh ← ERROR', e);
      state = AsyncValue.error(e, st);
    }
  }
}

/// Historical usage summaries for the current month (free tier).
@riverpod
FutureOr<List<UsageSummary>> monthlyUsageSummaries(
  Ref ref,
) async {
  final repo = ref.read(usageRepositoryProvider);
  return repo.getCurrentMonthSummaries();
}
