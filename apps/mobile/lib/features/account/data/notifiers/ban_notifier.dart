import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ban.dart';
import '../repositories/ban_repository.dart';

part 'ban_notifier.g.dart';

/// Notifier for managing ban state with real-time updates
@riverpod
class BanNotifier extends _$BanNotifier {
  @override
  Future<List<Ban>> build(String userId) async {
    final repository = ref.watch(banRepositoryProvider);
    return await repository.getUserBans(userId);
  }

  /// Refresh ban data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(banRepositoryProvider);
      return await repository.getUserBans(userId);
    });
  }

  /// Check if user has app-wide bans
  Future<bool> hasAppWideBans() async {
    final bans = await future;
    return bans.any((ban) => ban.scope == BanScope.app_wide);
  }

  /// Check if user is banned from specific feature
  Future<bool> isBannedFromFeature(String featureUniqueName) async {
    final bans = await future;

    // Check for app-wide bans first
    if (bans.any((ban) => ban.scope == BanScope.app_wide)) {
      return true;
    }

    // Check for feature-specific bans
    return bans.any((ban) =>
        ban.scope == BanScope.feature_specific &&
        ban.restrictedFeatures != null &&
        ban.restrictedFeatures!.contains(featureUniqueName));
  }

  /// Get ban for specific feature
  Future<Ban?> getFeatureBan(String featureUniqueName) async {
    final bans = await future;

    // Check for app-wide bans first
    final appWideBan =
        bans.where((ban) => ban.scope == BanScope.app_wide).firstOrNull;
    if (appWideBan != null) return appWideBan;

    // Then check for feature-specific bans
    return bans
        .where((ban) =>
            ban.scope == BanScope.feature_specific &&
            ban.restrictedFeatures != null &&
            ban.restrictedFeatures!.contains(featureUniqueName))
        .firstOrNull;
  }
}

/// Notifier for current user bans
@riverpod
class CurrentUserBanNotifier extends _$CurrentUserBanNotifier {
  @override
  Future<List<Ban>> build() async {
    final repository = ref.watch(banRepositoryProvider);
    return await repository.getCurrentUserBans();
  }

  /// Refresh current user ban data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(banRepositoryProvider);
      return await repository.getCurrentUserBans();
    });
  }

  /// Check if current user has app-wide bans
  Future<bool> hasAppWideBans() async {
    final bans = await future;
    return bans.any((ban) => ban.scope == BanScope.app_wide);
  }

  /// Check if current user is banned from specific feature
  Future<bool> isBannedFromFeature(String featureUniqueName) async {
    final bans = await future;

    // Check for app-wide bans first
    if (bans.any((ban) => ban.scope == BanScope.app_wide)) {
      return true;
    }

    // Check for feature-specific bans
    return bans.any((ban) =>
        ban.scope == BanScope.feature_specific &&
        ban.restrictedFeatures != null &&
        ban.restrictedFeatures!.contains(featureUniqueName));
  }

  /// Get ban for specific feature
  Future<Ban?> getFeatureBan(String featureUniqueName) async {
    final bans = await future;

    // Check for app-wide bans first
    final appWideBan =
        bans.where((ban) => ban.scope == BanScope.app_wide).firstOrNull;
    if (appWideBan != null) return appWideBan;

    // Then check for feature-specific bans
    return bans
        .where((ban) =>
            ban.scope == BanScope.feature_specific &&
            ban.restrictedFeatures != null &&
            ban.restrictedFeatures!.contains(featureUniqueName))
        .firstOrNull;
  }
}

/// Stream notifier for real-time ban updates
@riverpod
class BanStreamNotifier extends _$BanStreamNotifier {
  @override
  Stream<List<Ban>> build(String userId) {
    final repository = ref.watch(banRepositoryProvider);
    return repository.watchUserBans(userId);
  }
}

/// Stream notifier for current user ban updates
@riverpod
class CurrentUserBanStreamNotifier extends _$CurrentUserBanStreamNotifier {
  @override
  Stream<List<Ban>> build() {
    final repository = ref.watch(banRepositoryProvider);
    return repository.watchCurrentUserBans();
  }
}
