import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_notifier.g.dart';

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  SubscriptionService get service => ref.read(subscriptionServiceProvider);

  @override
  FutureOr<SubscriptionInfo> build() async {
    // Watch user changes to invalidate subscription data when user changes
    ref.watch(userNotifierProvider);

    // Load initial subscription status
    return await service.getSubscriptionInfo();
  }

  /// Purchase a subscription
  Future<void> purchaseSubscription(String productId) async {
    state = const AsyncValue.loading();
    try {
      final success = await service.purchaseSubscription(productId: productId);
      if (success) {
        // Refresh subscription info
        state = AsyncValue.data(await service.getSubscriptionInfo());
      } else {
        state = AsyncValue.error('Purchase failed', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Purchase with Package object (for RevenueCat integration)
  Future<bool> purchasePackage(Package package) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final success = await repository.purchasePackage(package);
      if (success) {
        // Force clear any cached validation to get fresh data
        await repository.forceClearCache();

        // Wait a moment for RevenueCat entitlements to propagate
        await Future.delayed(const Duration(seconds: 2));

        // Refresh subscription info with fresh data
        final freshInfo = await service.getSubscriptionInfo();
        state = AsyncValue.data(freshInfo);
        return true;
      }
      return false;
    } catch (e, st) {
      print('Purchase failed: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final info = await service.restorePurchases();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update subscription (for testing)
  Future<void> updateSubscriptionForTesting(SubscriptionInfo info) async {
    state = const AsyncValue.loading();
    try {
      await service.updateSubscriptionStatus(info);
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      return currentState.status == SubscriptionStatus.plus &&
          currentState.isActive;
    }
    return await service.isSubscriptionActive();
  }

  /// Check if a specific feature is available
  Future<bool> isFeatureAvailable(String featureName) async {
    return await service.isFeatureAvailable(featureName);
  }

  /// Force refresh subscription data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final info = await service.getSubscriptionInfo();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Force refresh with complete cache clearing
  Future<void> forceRefreshWithCacheClear() async {
    print('Subscription Notifier: Force refreshing with cache clear');
    final repository = ref.read(subscriptionRepositoryProvider);
    await repository.forceClearCache();
    state = AsyncValue.loading();

    // Wait a moment for cache clearing to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Invalidate to trigger fresh fetch
    ref.invalidateSelf();
    print('Subscription Notifier: Cache cleared and state invalidated');
  }

  /// Debug entitlement fetching with comprehensive logging
  Future<void> debugEntitlementFetching() async {
    final repository = ref.read(subscriptionRepositoryProvider);
    await repository.debugEntitlementFetching();
  }
}

// User-aware subscription status provider that invalidates when user changes
@riverpod
bool hasActiveSubscription(Ref ref) {
  // Watch user changes to automatically refresh subscription status
  final user = ref.watch(userNotifierProvider);
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

  // If user is null (logged out), always return false
  return user.when(
    data: (userData) {
      if (userData == null) {
        return false; // No user logged in
      }

      return subscriptionAsync.when(
        data: (subscription) =>
            subscription.status == SubscriptionStatus.plus &&
            subscription.isActive,
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// Provider to check if premium analytics is available
@riverpod
Future<bool> isPremiumAnalyticsAvailable(Ref ref) async {
  // Watch user changes
  final user = ref.watch(userNotifierProvider);

  return user.when(
    data: (userData) async {
      if (userData == null) return false;

      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      return await notifier.isFeatureAvailable('premium_analytics');
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// Provider for available packages from RevenueCat
@riverpod
Future<List<Package>> availablePackages(Ref ref) async {
  // Watch user changes to refresh packages if needed
  ref.watch(userNotifierProvider);

  final subscription = await ref.watch(subscriptionNotifierProvider.future);
  return subscription.availablePackages ?? [];
}
