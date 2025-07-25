import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_service.g.dart';

class SubscriptionService {
  final SubscriptionRepository _repository;

  SubscriptionService(this._repository);

  /// Get current subscription info
  Future<SubscriptionInfo> getSubscriptionInfo() async {
    return await _repository.getSubscriptionStatus();
  }

  /// Check if user has active Plus subscription
  Future<bool> isSubscriptionActive() async {
    return await _repository.hasActiveSubscription();
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription({
    required String productId,
  }) async {
    try {
      return await _repository.purchaseSubscription(productId);
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<SubscriptionInfo> restorePurchases() async {
    try {
      return await _repository.restorePurchases();
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  /// Update subscription status (for testing)
  Future<void> updateSubscriptionStatus(SubscriptionInfo info) async {
    await _repository.updateSubscriptionStatus(info);
  }

  /// Check if a feature is available for the current subscription
  Future<bool> isFeatureAvailable(String featureName) async {
    final info = await getSubscriptionInfo();

    // Define which features are available for each subscription level
    final plusFeatures = [
      'premium_analytics',
      'heat_map_calendar',
      'trigger_radar',
      'risk_clock',
      'mood_correlation',
      'community_perks',
      'smart_alerts',
    ];

    if (info.status == SubscriptionStatus.plus && info.isActive) {
      return plusFeatures.contains(featureName);
    }

    // Free features (if any)
    return false;
  }
}

@riverpod
SubscriptionService subscriptionService(Ref ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionService(repository);
}
