import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_repository.g.dart';

enum SubscriptionStatus {
  free,
  plus,
  loading,
  error,
}

class SubscriptionInfo {
  final SubscriptionStatus status;
  final DateTime? expirationDate;
  final String? productId;
  final bool isActive;

  const SubscriptionInfo({
    required this.status,
    this.expirationDate,
    this.productId,
    this.isActive = false,
  });

  SubscriptionInfo copyWith({
    SubscriptionStatus? status,
    DateTime? expirationDate,
    String? productId,
    bool? isActive,
  }) {
    return SubscriptionInfo(
      status: status ?? this.status,
      expirationDate: expirationDate ?? this.expirationDate,
      productId: productId ?? this.productId,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SubscriptionRepository {
  // In-memory storage for subscription status
  // This will be replaced with RevenueCat integration later
  SubscriptionInfo _subscriptionInfo = const SubscriptionInfo(
    status: SubscriptionStatus.free,
    isActive: false,
  );

  SubscriptionRepository();

  /// Get current subscription status
  Future<SubscriptionInfo> getSubscriptionStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _subscriptionInfo;
  }

  /// Update subscription status (for testing)
  Future<void> updateSubscriptionStatus(SubscriptionInfo info) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _subscriptionInfo = info;
  }

  /// Check if user has active Plus subscription
  Future<bool> hasActiveSubscription() async {
    final info = await getSubscriptionStatus();
    return info.status == SubscriptionStatus.plus && info.isActive;
  }

  /// Mock purchase subscription (for testing)
  Future<bool> purchaseSubscription(String productId) async {
    // Simulate purchase process
    await Future.delayed(const Duration(seconds: 2));

    // For now, always succeed
    _subscriptionInfo = SubscriptionInfo(
      status: SubscriptionStatus.plus,
      expirationDate: DateTime.now().add(const Duration(days: 30)),
      productId: productId,
      isActive: true,
    );

    return true;
  }

  /// Restore purchases
  Future<SubscriptionInfo> restorePurchases() async {
    // Simulate restore process
    await Future.delayed(const Duration(seconds: 1));
    return _subscriptionInfo;
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository();
}
