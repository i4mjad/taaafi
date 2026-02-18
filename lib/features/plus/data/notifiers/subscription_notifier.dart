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

  /// Test cross-platform subscription functionality
  /// This helps debug scenarios where users subscribed on one platform but are using another
  Future<void> testCrossPlatformSubscription() async {
    print('\n🌐 === CROSS-PLATFORM SUBSCRIPTION TEST ===');

    try {
      final repository = ref.read(subscriptionRepositoryProvider);

      // Step 1: Check if current platform has configuration issues
      print('Step 1 - Platform Configuration Check:');
      final hasPlatformIssues =
          await repository.hasPlatformConfigurationIssues();
      print('  - Platform has configuration issues: $hasPlatformIssues');

      if (hasPlatformIssues) {
        print(
            '  ⚠️  This platform cannot fetch products - testing cross-platform subscription access...');
      } else {
        print('  ✅ Platform configuration is working normally');
      }

      // Step 2: Test subscription status fetching with cross-platform support
      print('Step 2 - Cross-Platform Subscription Status:');
      final subscriptionInfo = await repository.getSubscriptionStatus();

      print('  - Subscription Status: ${subscriptionInfo.status}');
      print('  - Is Active: ${subscriptionInfo.isActive}');
      print('  - Product ID: ${subscriptionInfo.productId}');
      print('  - Expiration: ${subscriptionInfo.expirationDate}');
      print(
          '  - Available Packages: ${subscriptionInfo.availablePackages?.length ?? 0}');

      // Step 3: Test entitlement check
      print('Step 3 - Entitlement Check:');
      final hasEntitlement = subscriptionInfo.hasEntitlement('taaafi_plus');
      final hasActiveSubscription = await repository.hasActiveSubscription();

      print('  - Has taaafi_plus entitlement: $hasEntitlement');
      print('  - hasActiveSubscription(): $hasActiveSubscription');

      // Step 4: Analysis and recommendations
      print('Step 4 - Cross-Platform Analysis:');

      if (hasPlatformIssues && hasActiveSubscription) {
        print('  ✅ SUCCESS: User has valid cross-platform subscription');
        print(
            '  📱 Subscription from another platform is being recognized correctly');
      } else if (hasPlatformIssues && !hasActiveSubscription) {
        print(
            '  ⚠️  Platform configuration issues detected and no active subscription found');
        print(
            '  🔧 If user reports having a subscription, check RevenueCat dashboard');
      } else if (!hasPlatformIssues && hasActiveSubscription) {
        print('  ✅ SUCCESS: Normal subscription working correctly');
      } else {
        print('  📝 No active subscription detected (expected for free users)');
      }

      // Step 5: User action recommendations
      print('Step 5 - User Action Recommendations:');
      if (hasPlatformIssues && hasActiveSubscription) {
        print(
            '  - User can access premium features despite platform config issues');
        print('  - New purchases may not be available on this platform');
        print(
            '  - Recommend using the original platform for subscription management');
      } else if (hasPlatformIssues && !hasActiveSubscription) {
        print(
            '  - Recommend using "Restore Purchases" to sync cross-platform subscription');
        print(
            '  - If still not working, user may need to use original platform');
      }
    } catch (e, stackTrace) {
      print('❌ CROSS-PLATFORM TEST ERROR: $e');
      print('Stack trace: $stackTrace');
    }

    print('=== END CROSS-PLATFORM SUBSCRIPTION TEST ===\n');
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

// Provider to check if subscription is active AND will renew (not cancelled)
// Used for delete account screen - if subscription is set to cancel, user can proceed
@riverpod
bool hasActiveRenewingSubscription(Ref ref) {
  final user = ref.watch(userNotifierProvider);
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

  return user.when(
    data: (userData) {
      if (userData == null) {
        return false;
      }

      return subscriptionAsync.when(
        data: (subscription) {
          // Must have active plus subscription
          if (subscription.status != SubscriptionStatus.plus ||
              !subscription.isActive) {
            return false;
          }

          // Check if subscription will renew (not cancelled)
          final customerInfo = subscription.customerInfo;
          if (customerInfo != null) {
            final entitlement = customerInfo.entitlements.active['taaafi_plus'];
            if (entitlement != null) {
              // If willRenew is false, subscription is set to cancel
              return entitlement.willRenew;
            }
          }

          // Fallback: if we can't determine willRenew, assume it will renew
          return true;
        },
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
