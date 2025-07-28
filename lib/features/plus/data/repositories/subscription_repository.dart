import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // SharedPreferences keys
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionActiveKey = 'subscription_active';
  static const String _subscriptionExpirationKey = 'subscription_expiration';
  static const String _subscriptionProductIdKey = 'subscription_product_id';

  SubscriptionRepository();

  /// Get current subscription status
  Future<SubscriptionInfo> getSubscriptionStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();

    // Load from SharedPreferences
    final statusString = prefs.getString(_subscriptionStatusKey) ?? 'free';
    final isActive = prefs.getBool(_subscriptionActiveKey) ?? false;
    final expirationTimestamp = prefs.getInt(_subscriptionExpirationKey);
    final productId = prefs.getString(_subscriptionProductIdKey);

    final status = SubscriptionStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => SubscriptionStatus.free,
    );

    final expirationDate = expirationTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(expirationTimestamp)
        : null;

    return SubscriptionInfo(
      status: status,
      isActive: isActive,
      expirationDate: expirationDate,
      productId: productId,
    );
  }

  /// Update subscription status (for testing)
  Future<void> updateSubscriptionStatus(SubscriptionInfo info) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();

    // Save to SharedPreferences
    await prefs.setString(_subscriptionStatusKey, info.status.name);
    await prefs.setBool(_subscriptionActiveKey, info.isActive);

    if (info.expirationDate != null) {
      await prefs.setInt(_subscriptionExpirationKey,
          info.expirationDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_subscriptionExpirationKey);
    }

    if (info.productId != null) {
      await prefs.setString(_subscriptionProductIdKey, info.productId!);
    } else {
      await prefs.remove(_subscriptionProductIdKey);
    }
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
    final newSubscription = SubscriptionInfo(
      status: SubscriptionStatus.plus,
      expirationDate: DateTime.now().add(const Duration(days: 30)),
      productId: productId,
      isActive: true,
    );

    await updateSubscriptionStatus(newSubscription);
    return true;
  }

  /// Restore purchases
  Future<SubscriptionInfo> restorePurchases() async {
    // Simulate restore process
    await Future.delayed(const Duration(seconds: 1));
    return await getSubscriptionStatus();
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository();
}
