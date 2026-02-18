import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/revenue_cat_service.dart';
import '../../application/revenue_cat_auth_sync_service.dart';

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
    final hasPlus =
        customerInfo.entitlements.active['taaafi_plus']?.isActive ?? false;
    final plusEntitlement = customerInfo.entitlements.all['taaafi_plus'];

    return SubscriptionInfo(
      status: hasPlus ? SubscriptionStatus.plus : SubscriptionStatus.free,
      isActive: hasPlus,
      expirationDate: plusEntitlement?.expirationDate != null
          ? DateTime.tryParse(plusEntitlement!.expirationDate!)
          : null,
      productId: plusEntitlement?.productIdentifier,
      availablePackages: packages,
      customerInfo: customerInfo,
    );
  }
}

class SubscriptionRepository {
  final RevenueCatService _revenueCatService;
  final RevenueCatAuthSyncService _authSyncService;

  // SharedPreferences keys (for caching)
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionActiveKey = 'subscription_active';
  static const String _subscriptionExpirationKey = 'subscription_expiration';
  static const String _subscriptionProductIdKey = 'subscription_product_id';
  static const String _subscriptionUserIdKey =
      'subscription_user_id'; // NEW: Track which user the cache is for

  SubscriptionRepository(this._revenueCatService, this._authSyncService);

  /// Initialize RevenueCat with user ID
  /// Note: This is now primarily handled by RevenueCatAuthSyncService
  /// for automatic Firebase auth synchronization
  Future<void> initialize(String? userId) async {
    await _revenueCatService.initialize(userId: userId);
  }

  /// Ensure user is properly synced before operations (optimized)
  Future<void> _ensureUserSynced() async {
    // Quick check if sync is needed before doing expensive validation
    if (!_authSyncService.isSyncNeeded()) {
      return; // Skip if no sync needed
    }

    final isSynced = await _authSyncService.isUserSynced();
    if (!isSynced) {
      print('Subscription Repository: User not synced, forcing sync');
      await _authSyncService.forceSyncCurrentUser();
    }
  }

  /// Manual user sync for testing or special cases
  /// The auth sync service handles this automatically for Firebase auth
  Future<void> syncUserWithRevenueCat(String? userId) async {
    if (userId != null) {
      await _revenueCatService.login(userId);
    } else {
      await _revenueCatService.logout();
    }
  }

  /// Clear all cache keys and force fresh validation
  Future<void> forceClearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionStatusKey);
    await prefs.remove(_subscriptionActiveKey);
    await prefs.remove(_subscriptionExpirationKey);
    await prefs.remove(_subscriptionProductIdKey);
    await prefs.remove(_subscriptionUserIdKey);

    // Also force fresh user validation in RevenueCat service
    await _revenueCatService.forceUserValidation();
    print(
        'Subscription Repository: All caches cleared and user validation forced');
  }

  /// Check if current platform has configuration issues (for cross-platform scenarios)
  /// Returns true if offerings can't be fetched due to platform configuration
  Future<bool> hasPlatformConfigurationIssues() async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      return offerings.current?.availablePackages.isEmpty ?? true;
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('CONFIGURATION_ERROR') ||
          errorMessage.contains('could be fetched from App Store Connect')) {
        print(
            'Subscription Repository: Platform configuration issues detected - $e');
        return true;
      }
      return false;
    }
  }

  /// COMPREHENSIVE DEBUG METHOD - Traces every step of entitlement fetching
  Future<void> debugEntitlementFetching() async {
    print('\n🔍 === COMPREHENSIVE ENTITLEMENT DEBUG ===');

    try {
      // Step 1: Check Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('Step 1 - Firebase User: ${firebaseUser?.uid ?? "NOT LOGGED IN"}');

      if (firebaseUser == null) {
        print('❌ CRITICAL: No Firebase user logged in');
        return;
      }

      // Step 2: Ensure user sync
      print('Step 2 - Ensuring user sync...');
      await _ensureUserSynced();

      // Step 3: Get raw customer info from RevenueCat
      print('Step 3 - Fetching raw customer info...');
      final customerInfo = await _revenueCatService.getCustomerInfo();

      // Step 4: Log customer info details
      print('Step 4 - Customer Info Analysis:');
      print('  - Original App User ID: ${customerInfo.originalAppUserId}');
      print('  - Management URL: ${customerInfo.managementURL}');
      print('  - First Seen: ${customerInfo.firstSeen}');
      print('  - Latest Expiration Date: ${customerInfo.latestExpirationDate}');
      print('  - Active Subscriptions: ${customerInfo.activeSubscriptions}');
      print(
          '  - All Purchased Product IDs: ${customerInfo.allPurchasedProductIdentifiers}');

      // Step 5: Detailed entitlements analysis
      print('Step 5 - Entitlements Deep Dive:');
      final allEntitlements = customerInfo.entitlements.all;
      final activeEntitlements = customerInfo.entitlements.active;

      print('  - Total entitlements count: ${allEntitlements.length}');
      print('  - Active entitlements count: ${activeEntitlements.length}');
      print('  - All entitlement keys: ${allEntitlements.keys.toList()}');
      print('  - Active entitlement keys: ${activeEntitlements.keys.toList()}');

      // Step 6: Check for our specific entitlement
      print('Step 6 - Checking for "taaafi_plus" entitlement:');
      if (allEntitlements.containsKey('taaafi_plus')) {
        final taaafiPlusEntitlement = allEntitlements['taaafi_plus']!;
        print('  ✅ taaafi_plus entitlement FOUND');
        print('  - Identifier: ${taaafiPlusEntitlement.identifier}');
        print(
            '  - Product Identifier: ${taaafiPlusEntitlement.productIdentifier}');
        print('  - Is Active: ${taaafiPlusEntitlement.isActive}');
        print('  - Will Renew: ${taaafiPlusEntitlement.willRenew}');
        print(
            '  - Latest Purchase Date: ${taaafiPlusEntitlement.latestPurchaseDate}');
        print(
            '  - Original Purchase Date: ${taaafiPlusEntitlement.originalPurchaseDate}');
        print('  - Expiration Date: ${taaafiPlusEntitlement.expirationDate}');
        print(
            '  - Unsubscribe Detected At: ${taaafiPlusEntitlement.unsubscribeDetectedAt}');
        print(
            '  - Billing Issue Detected At: ${taaafiPlusEntitlement.billingIssueDetectedAt}');
        print('  - Store: ${taaafiPlusEntitlement.store}');
        print('  - Period Type: ${taaafiPlusEntitlement.periodType}');
        print('  - Ownership Type: ${taaafiPlusEntitlement.ownershipType}');

        // Check if it's in active entitlements
        if (activeEntitlements.containsKey('taaafi_plus')) {
          print('  ✅ taaafi_plus is in ACTIVE entitlements');
        } else {
          print(
              '  ❌ taaafi_plus is NOT in active entitlements (but exists in all)');
        }
      } else {
        print('  ❌ taaafi_plus entitlement NOT FOUND');
        print('  Available entitlements:');
        allEntitlements.forEach((key, entitlement) {
          print(
              '    - $key: isActive=${entitlement.isActive}, product=${entitlement.productIdentifier}');
        });
      }

      // Step 7: Test cross-platform offerings support
      print('Step 7 - Cross-platform offerings check:');
      Offerings? offerings;
      List<Package>? packages;

      try {
        offerings = await _revenueCatService.getOfferings();
        packages = offerings.current?.availablePackages;
        print('  ✅ Offerings fetched successfully');
        print('  - Available packages count: ${packages?.length ?? 0}');
      } catch (e) {
        print('  ⚠️  Offerings failed (cross-platform scenario) - $e');
        final isConfigError = e.toString().contains('CONFIGURATION_ERROR') ||
            e.toString().contains('could be fetched from App Store Connect');
        if (isConfigError) {
          print(
              '  🔧 This is a platform configuration issue - subscription status should still work');
        }
      }

      // Step 8: Test our subscription info creation with cross-platform handling
      print(
          'Step 8 - Testing SubscriptionInfo creation with cross-platform support:');
      final subscriptionInfo =
          SubscriptionInfo.fromRevenueCat(customerInfo, packages);

      print('  - Generated Status: ${subscriptionInfo.status}');
      print('  - Generated IsActive: ${subscriptionInfo.isActive}');
      print('  - Generated Product ID: ${subscriptionInfo.productId}');
      print('  - Generated Expiration: ${subscriptionInfo.expirationDate}');
      print(
          '  - Available Packages: ${packages?.length ?? 0} (null = platform config issues)');

      // Step 9: Test hasEntitlement method
      print('Step 9 - Testing hasEntitlement method:');
      final hasEntitlementResult =
          subscriptionInfo.hasEntitlement('taaafi_plus');
      print('  - hasEntitlement("taaafi_plus"): $hasEntitlementResult');

      // Step 10: Test raw entitlement check
      print('Step 10 - Raw entitlement checks:');
      final rawActiveCheck =
          customerInfo.entitlements.active['taaafi_plus']?.isActive ?? false;
      final rawAllCheck =
          customerInfo.entitlements.all['taaafi_plus']?.isActive ?? false;
      print('  - Raw active["taaafi_plus"]?.isActive: $rawActiveCheck');
      print('  - Raw all["taaafi_plus"]?.isActive: $rawAllCheck');

      // Step 11: Cross-platform scenario analysis
      print('Step 11 - Cross-platform scenario analysis:');
      final hasPlatformIssues = await hasPlatformConfigurationIssues();
      print('  - Platform has configuration issues: $hasPlatformIssues');
      if (hasPlatformIssues && (rawActiveCheck || rawAllCheck)) {
        print(
            '  ✅ SUCCESS: User has valid cross-platform subscription despite platform config issues');
      }

      // Step 12: Check what our hasActiveSubscription would return
      print('Step 12 - Final hasActiveSubscription logic:');
      final hasEntitlement = subscriptionInfo.hasEntitlement('taaafi_plus');
      final hasLegacyStatus =
          (subscriptionInfo.status == SubscriptionStatus.plus &&
              subscriptionInfo.isActive);
      final finalResult = hasEntitlement || hasLegacyStatus;

      print('  - hasEntitlement: $hasEntitlement');
      print('  - hasLegacyStatus: $hasLegacyStatus');
      print('  - Final Result: $finalResult');

      if (!finalResult) {
        print(
            '  ❌ PROBLEM IDENTIFIED: hasActiveSubscription would return FALSE');
        print('  🔧 Debugging suggestions:');
        if (allEntitlements.containsKey('taaafi_plus')) {
          final ent = allEntitlements['taaafi_plus']!;
          if (!ent.isActive) {
            print('    - Entitlement exists but isActive=false');
            print('    - Check expiration date: ${ent.expirationDate}');
            print(
                '    - Check if subscription was cancelled: ${ent.unsubscribeDetectedAt}');
          }
        } else {
          print(
              '    - Entitlement completely missing - check RevenueCat dashboard product linking');
        }
      } else {
        print('  ✅ SUCCESS: hasActiveSubscription would return TRUE');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG ERROR: $e');
      print('Stack trace: $stackTrace');
    }

    print('=== END COMPREHENSIVE ENTITLEMENT DEBUG ===\n');
  }

  /// Get current subscription status from RevenueCat (with caching fallback)
  Future<SubscriptionInfo> getSubscriptionStatus() async {
    try {
      // Optimized user sync check
      await _ensureUserSynced();

      // Try to get customer info first (this contains subscription status)
      final customerInfo = await _revenueCatService.getCustomerInfo();

      // Try to get offerings, but don't fail if not available (cross-platform support)
      final offerings = await _revenueCatService.getOfferingsOrNull();
      final packages = offerings?.current?.availablePackages;

      final subscription =
          SubscriptionInfo.fromRevenueCat(customerInfo, packages);

      // Cache the fresh data locally for offline access
      await _cacheSubscriptionStatus(subscription);

      print(
          'Subscription Repository: Successfully got subscription status from RevenueCat');
      return subscription;
    } catch (e) {
      print('Failed to get subscription status from RevenueCat: $e');
      // Fallback to cached data if RevenueCat fails
      final cachedInfo = await _getCachedSubscriptionStatus();
      print(
          'Subscription Repository: Using cached subscription status - isActive: ${cachedInfo.isActive}, status: ${cachedInfo.status}');
      return cachedInfo;
    }
  }

  /// Cache subscription status locally
  Future<void> _cacheSubscriptionStatus(SubscriptionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    await prefs.setString(_subscriptionStatusKey, info.status.name);
    await prefs.setBool(_subscriptionActiveKey, info.isActive);

    // Store which user this cache is for
    if (currentUser?.uid != null) {
      await prefs.setString(_subscriptionUserIdKey, currentUser!.uid);
    } else {
      await prefs.remove(_subscriptionUserIdKey);
    }

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
    final currentUser = FirebaseAuth.instance.currentUser;
    final cachedUserId = prefs.getString(_subscriptionUserIdKey);

    // Check if cached data is for the current user
    if (currentUser?.uid != cachedUserId) {
      // Only log if there was actually cached data for a different user
      if (cachedUserId != null) {
        print(
            'Subscription Repository: Cached data is for different user, returning default');
      }
      return const SubscriptionInfo(
        status: SubscriptionStatus.free,
        isActive: false,
      );
    }

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
    try {
      // Optimized user sync check
      await _ensureUserSynced();

      final info = await getSubscriptionStatus();

      if (info.customerInfo != null) {
        final entitlements = info.customerInfo!.entitlements;
        final plusEntitlement = entitlements.all['taaafi_plus'];
      }

      // Use RevenueCat entitlement check if available, otherwise fallback to legacy check
      final hasEntitlement = info.hasEntitlement('taaafi_plus');
      final hasLegacyStatus =
          (info.status == SubscriptionStatus.plus && info.isActive);
      final result = hasEntitlement || hasLegacyStatus;

      return result;
    } catch (e) {
      print('Error checking active subscription: $e');
      // Fallback to cached data
      final cachedInfo = await _getCachedSubscriptionStatus();
      print(
          'Using cached subscription status: ${cachedInfo.isActive && cachedInfo.status == SubscriptionStatus.plus}');
      return cachedInfo.isActive &&
          cachedInfo.status == SubscriptionStatus.plus;
    }
  }

  /// Purchase subscription with RevenueCat
  Future<bool> purchaseSubscription(String productId) async {
    try {
      // Force fresh sync before purchase (critical operation)
      await _authSyncService.forceSyncCurrentUser();

      final offerings = await _revenueCatService.getOfferings();
      final package = offerings.current?.availablePackages
          .firstWhere((pkg) => pkg.storeProduct.identifier == productId);

      if (package != null) {
        await _revenueCatService.purchasePackage(package);
        return true;
      }
      return false;
    } catch (e) {
      // Check if this is a cross-platform configuration issue
      final errorMessage = e.toString();
      if (errorMessage.contains('CONFIGURATION_ERROR') ||
          errorMessage.contains('could be fetched from App Store Connect')) {
        throw Exception(
            'Purchase not available on this platform due to configuration issues. '
            'Your existing subscription from other platforms is still valid. '
            'Error: $e');
      }
      throw Exception('Purchase failed: $e');
    }
  }

  /// Purchase with Package object (NEW)
  Future<bool> purchasePackage(Package package) async {
    try {
      // Force fresh sync before purchase (critical operation)
      await _authSyncService.forceSyncCurrentUser();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == null) {
        throw Exception('User must be logged in to make purchases');
      }

      print(
          'Subscription Repository: Making purchase for user ${currentUser!.uid}');
      await _revenueCatService.purchasePackage(package);
      print(
          'Subscription Repository: Purchase completed for user ${currentUser.uid}');
      return true;
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  /// Restore purchases with RevenueCat
  Future<SubscriptionInfo> restorePurchases() async {
    try {
      // Optimized user sync check
      await _ensureUserSynced();

      final customerInfo = await _revenueCatService.restorePurchases();

      // Try to get offerings, but don't fail if not available (cross-platform support)
      final offerings = await _revenueCatService.getOfferingsOrNull();
      final packages = offerings?.current?.availablePackages;

      final subscription =
          SubscriptionInfo.fromRevenueCat(customerInfo, packages);
      print(
          'Subscription Repository: Restore purchases completed, subscription active: ${subscription.isActive}');

      return subscription;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  final revenueCatService = ref.read(revenueCatServiceProvider);
  final authSyncService = ref.read(revenueCatAuthSyncServiceProvider);
  return SubscriptionRepository(revenueCatService, authSyncService);
}
