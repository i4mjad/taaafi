import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/fort/data/repositories/usage_repository.dart';
import 'package:reboot_app_3/features/fort/data/services/native_usage_bridge.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usage_notifier.g.dart';

/// Whether the user has granted usage access permission.
@riverpod
class UsagePermission extends _$UsagePermission {
  @override
  FutureOr<bool> build() async {
    final bridge = ref.read(nativeUsageBridgeProvider);
    return bridge.checkUsagePermission();
  }

  Future<bool> requestPermission() async {
    state = const AsyncValue.loading();
    final bridge = ref.read(nativeUsageBridgeProvider);
    final granted = await bridge.requestUsagePermission();
    state = AsyncValue.data(granted);
    return granted;
  }

  Future<void> recheck() async {
    final bridge = ref.read(nativeUsageBridgeProvider);
    final granted = await bridge.checkUsagePermission();
    state = AsyncValue.data(granted);
  }
}

/// Today's usage data — fetches from native and persists to Firestore.
@riverpod
class UsageNotifier extends _$UsageNotifier {
  @override
  FutureOr<UsageSummary> build() async {
    // Wait for user doc to be ready
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    if (userDocAsync.isLoading || userDocAsync.hasError) {
      return UsageSummary.empty(DateTime.now());
    }
    if (userDocAsync.value == null) {
      return UsageSummary.empty(DateTime.now());
    }

    final accountStatus = ref.watch(accountStatusProvider);
    if (accountStatus != AccountStatus.ok) {
      return UsageSummary.empty(DateTime.now());
    }

    // Check permission first
    final bridge = ref.read(nativeUsageBridgeProvider);
    final hasPermission = await bridge.checkUsagePermission();
    if (!hasPermission) {
      return UsageSummary.empty(DateTime.now());
    }

    // Fetch fresh data from native
    final summary = await bridge.getTodayUsage();

    // Persist to Firestore in the background
    if (summary.categories.isNotEmpty) {
      final repo = ref.read(usageRepositoryProvider);
      repo.saveUsageSummary(summary);
    }

    return summary;
  }

  /// Refresh usage data from native platform.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final bridge = ref.read(nativeUsageBridgeProvider);
      final summary = await bridge.getTodayUsage();

      if (summary.categories.isNotEmpty) {
        final repo = ref.read(usageRepositoryProvider);
        repo.saveUsageSummary(summary);
      }

      state = AsyncValue.data(summary);
    } catch (e, st) {
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
