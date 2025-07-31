import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_notifier.g.dart';

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  SubscriptionService get service => ref.read(subscriptionServiceProvider);

  @override
  FutureOr<SubscriptionInfo> build() async {
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
        // Refresh subscription info
        state = AsyncValue.data(await service.getSubscriptionInfo());
        return true;
      }
      return false;
    } catch (e, st) {
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
}

// Simple provider to check subscription status
@riverpod
bool hasActiveSubscription(Ref ref) {
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

  return subscriptionAsync.when(
    data: (subscription) =>
        subscription.status == SubscriptionStatus.plus && subscription.isActive,
    loading: () => false,
    error: (_, __) => false,
  );
}

// Provider to check if premium analytics is available
@riverpod
Future<bool> isPremiumAnalyticsAvailable(Ref ref) async {
  final notifier = ref.read(subscriptionNotifierProvider.notifier);
  return await notifier.isFeatureAvailable('premium_analytics');
}

// Provider for available packages from RevenueCat
@riverpod
Future<List<Package>> availablePackages(Ref ref) async {
  final subscription = await ref.watch(subscriptionNotifierProvider.future);
  return subscription.availablePackages ?? [];
}
