import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

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
  // NEW: RevenueCat data
  final List<Package>? availablePackages;
  final CustomerInfo? customerInfo;

  const SubscriptionInfo({
    required this.status,
    this.expirationDate,
    this.productId,
    this.isActive = false,
    this.availablePackages, // NEW
    this.customerInfo, // NEW
  });

  SubscriptionInfo copyWith({
    SubscriptionStatus? status,
    DateTime? expirationDate,
    String? productId,
    bool? isActive,
    List<Package>? availablePackages, // NEW
    CustomerInfo? customerInfo, // NEW
  }) {
    return SubscriptionInfo(
      status: status ?? this.status,
      expirationDate: expirationDate ?? this.expirationDate,
      productId: productId ?? this.productId,
      isActive: isActive ?? this.isActive,
      availablePackages: availablePackages ?? this.availablePackages,
      customerInfo: customerInfo ?? this.customerInfo,
    );
  }

  // NEW: Helper to check RevenueCat entitlements
  bool hasEntitlement(String entitlementId) {
    return customerInfo?.entitlements.active[entitlementId]?.isActive ?? false;
  }

  // NEW: Create from RevenueCat data
  static SubscriptionInfo fromRevenueCat(
      CustomerInfo customerInfo, List<Package>? packages) {
    final hasPlus = customerInfo.entitlements.active['plus']?.isActive ?? false;
    final plusEntitlement = customerInfo.entitlements.all['plus'];

    return SubscriptionInfo(
      status: hasPlus ? SubscriptionStatus.plus : SubscriptionStatus.free,
      isActive: hasPlus,
      expirationDate:
          null, // TODO: Fix type mismatch - plusEntitlement?.expirationDate,
      productId: plusEntitlement?.productIdentifier,
      availablePackages: packages,
      customerInfo: customerInfo,
    );
  }
}

class SubscriptionRepository {
  final RevenueCatService _revenueCatService;

  // SharedPreferences keys (for caching)
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionActiveKey = 'subscription_active';
  static const String _subscriptionExpirationKey = 'subscription_expiration';
  static const String _subscriptionProductIdKey = 'subscription_product_id';

  SubscriptionRepository(this._revenueCatService);

  /// Initialize RevenueCat with user ID
  Future<void> initialize(String? userId) async {
    await _revenueCatService.initialize(userId: userId);
  }

  /// Get current subscription status from RevenueCat (with caching fallback)
  Future<SubscriptionInfo> getSubscriptionStatus() async {
    try {
      // Try to get fresh data from RevenueCat
      final customerInfo = await _revenueCatService.getCustomerInfo();
      final offerings = await _revenueCatService.getOfferings();
      final packages = offerings.current?.availablePackages;

      final subscription =
          SubscriptionInfo.fromRevenueCat(customerInfo, packages);

      // Cache the fresh data locally for offline access
      await _cacheSubscriptionStatus(subscription);

      return subscription;
    } catch (e) {
      // Fallback to cached data if RevenueCat fails
      return await _getCachedSubscriptionStatus();
    }
  }

  /// Cache subscription status locally
  Future<void> _cacheSubscriptionStatus(SubscriptionInfo info) async {
    final prefs = await SharedPreferences.getInstance();

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

  /// Get cached subscription status from SharedPreferences
  Future<SubscriptionInfo> _getCachedSubscriptionStatus() async {
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

  /// Check if user has active Plus subscription (using RevenueCat entitlements)
  Future<bool> hasActiveSubscription() async {
    final info = await getSubscriptionStatus();
    // Use RevenueCat entitlement check if available, otherwise fallback to legacy check
    return info.hasEntitlement('plus') ||
        (info.status == SubscriptionStatus.plus && info.isActive);
  }

  /// Purchase subscription with RevenueCat
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      final package = offerings.current?.availablePackages
          .firstWhere((pkg) => pkg.storeProduct.identifier == productId);

      if (package != null) {
        await _revenueCatService.purchasePackage(package);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  /// Purchase with Package object (NEW)
  Future<bool> purchasePackage(Package package) async {
    try {
      await _revenueCatService.purchasePackage(package);
      return true;
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  /// Restore purchases with RevenueCat
  Future<SubscriptionInfo> restorePurchases() async {
    try {
      final customerInfo = await _revenueCatService.restorePurchases();
      final offerings = await _revenueCatService.getOfferings();
      final packages = offerings.current?.availablePackages;

      return SubscriptionInfo.fromRevenueCat(customerInfo, packages);
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  final revenueCatService = ref.read(revenueCatServiceProvider);
  return SubscriptionRepository(revenueCatService);
}
