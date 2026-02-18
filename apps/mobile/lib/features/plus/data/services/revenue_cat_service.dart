import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'revenue_cat_service.g.dart';

/// Exception thrown when RevenueCat is not available
class RevenueCatNotAvailableException implements Exception {
  final String message;
  RevenueCatNotAvailableException(this.message);

  @override
  String toString() => 'RevenueCatNotAvailableException: $message';
}

class RevenueCatService {
  //TODO: consider adding those to a .env file
  static const String _apiKeyIOS = 'appl_VJlBGrlcGTKcySomcGMsBdazXTo';
  static const String _apiKeyAndroid = 'goog_CuAPzQlQmGCxsqzDgdkgmAmcWVB';

  // Track if RevenueCat has been configured to prevent multiple configurations
  static bool _isConfigured = false;

  // Cache the last validated user to prevent redundant sync checks
  static String? _lastValidatedUserId;
  static DateTime? _lastValidatedTime;
  static const Duration _validationCacheDuration = Duration(minutes: 5);

  /// Initialize RevenueCat - only configures once to prevent multiple accounts
  Future<void> initialize({String? userId}) async {
    try {
      // Only configure RevenueCat once to prevent creating multiple anonymous accounts
      if (!_isConfigured) {
        await Purchases.setLogLevel(LogLevel.debug);

        PurchasesConfiguration configuration;
        if (Platform.isAndroid) {
          configuration = PurchasesConfiguration(_apiKeyAndroid);
        } else if (Platform.isIOS) {
          configuration = PurchasesConfiguration(_apiKeyIOS);
        } else {
          throw UnsupportedError('Platform not supported');
        }

        await Purchases.configure(configuration);
        _isConfigured = true;
        print('RevenueCat: Successfully configured for the first time');
      }

      // Always ensure the correct user is logged in after configuration
      if (userId != null) {
        await _ensureUserLoggedIn(userId);
      }

      print(
          'RevenueCat: Successfully initialized${userId != null ? " for user $userId" : " in anonymous mode"}');
    } on MissingPluginException catch (e) {
      print('RevenueCat: Plugin not properly installed - ${e.message}');
      print(
          'RevenueCat: This usually means the app needs to be rebuilt after adding the plugin');
      throw RevenueCatNotAvailableException(
          'RevenueCat plugin not available: ${e.message}');
    } catch (e) {
      print('RevenueCat: Initialization failed - $e');
      rethrow;
    }
  }

  /// Check if user validation is still fresh to avoid redundant checks
  bool _isValidationFresh(String userId) {
    if (_lastValidatedUserId != userId) return false;
    if (_lastValidatedTime == null) return false;

    final now = DateTime.now();
    return now.difference(_lastValidatedTime!) < _validationCacheDuration;
  }

  /// Mark user as validated
  void _markUserAsValidated(String userId) {
    _lastValidatedUserId = userId;
    _lastValidatedTime = DateTime.now();
  }

  /// Ensure the correct user is logged into RevenueCat
  Future<void> _ensureUserLoggedIn(String userId) async {
    try {
      // Skip validation if recently validated for same user
      if (_isValidationFresh(userId)) {
        return;
      }

      final customerInfo = await Purchases.getCustomerInfo();
      final currentUserId = customerInfo.originalAppUserId;

      // Only login if the current user is different
      if (currentUserId != userId) {
        print('RevenueCat: Switching from user $currentUserId to $userId');
        await Purchases.logIn(userId);
        print('RevenueCat: Successfully logged in user $userId');
        _markUserAsValidated(userId);
      } else {
        // Only log on first validation or significant time gap
        if (!_isValidationFresh(userId)) {
          print('RevenueCat: User $userId confirmed logged in');
        }
        _markUserAsValidated(userId);
      }
    } catch (e) {
      print('RevenueCat: Error ensuring user login - $e');
      // Try to login anyway
      await Purchases.logIn(userId);
      _markUserAsValidated(userId);
    }
  }

  /// Ensure current Firebase user is logged into RevenueCat before operations
  Future<void> ensureCurrentUserLoggedIn() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != null) {
      await _ensureUserLoggedIn(currentUser!.uid);
    } else {
      // Clear validation cache if no user
      _lastValidatedUserId = null;
      _lastValidatedTime = null;

      // If no Firebase user, ensure we're in anonymous mode
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.originalAppUserId.startsWith('firebase:')) {
        // We have a Firebase user logged in but no current Firebase user - logout
        await Purchases.logOut();
        print('RevenueCat: Logged out to anonymous mode');
      }
    }
  }

  /// Force refresh user validation (for explicit sync operations)
  Future<void> forceUserValidation() async {
    _lastValidatedUserId = null;
    _lastValidatedTime = null;
    await ensureCurrentUserLoggedIn();
  }

  /// Check if RevenueCat is available (for graceful degradation)
  Future<bool> isAvailable() async {
    try {
      await Purchases.getCustomerInfo();
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return true; // Other errors don't mean the plugin is unavailable
    }
  }

  /// Get current customer info from RevenueCat
  Future<CustomerInfo> getCustomerInfo() async {
    // Ensure correct user is logged in before fetching customer info
    await ensureCurrentUserLoggedIn();
    return await Purchases.getCustomerInfo();
  }

  /// Get available offerings and packages
  Future<Offerings> getOfferings() async {
    // Ensure correct user is logged in before fetching offerings
    await ensureCurrentUserLoggedIn();
    return await Purchases.getOfferings();
  }

  /// Get available offerings with error handling for cross-platform scenarios
  /// Returns null if offerings can't be fetched (e.g. platform configuration issues)
  /// but doesn't affect subscription status checking
  Future<Offerings?> getOfferingsOrNull() async {
    try {
      // Ensure correct user is logged in before fetching offerings
      await ensureCurrentUserLoggedIn();
      return await Purchases.getOfferings();
    } catch (e) {
      print('RevenueCat: Could not fetch offerings for current platform - $e');
      print(
          'RevenueCat: This may be due to platform configuration issues but does not affect existing subscriptions');
      return null;
    }
  }

  /// Purchase a specific package
  Future<CustomerInfo> purchasePackage(Package package) async {
    // Critical: Force user validation before purchase (no cache)
    await forceUserValidation();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == null) {
      throw Exception('User must be logged in to make purchases');
    }

    print('RevenueCat: Making purchase for user ${currentUser!.uid}');
    final result = await Purchases.purchasePackage(package);
    print('RevenueCat: Purchase successful for user ${currentUser.uid}');
    return result.customerInfo;
  }

  /// Restore previous purchases
  Future<CustomerInfo> restorePurchases() async {
    // Ensure correct user is logged in before restoring
    await ensureCurrentUserLoggedIn();
    return await Purchases.restorePurchases();
  }

  /// Login user to RevenueCat
  Future<CustomerInfo> login(String userId) async {
    // Clear cache to force fresh validation
    _lastValidatedUserId = null;
    _lastValidatedTime = null;
    await _ensureUserLoggedIn(userId);
    return await Purchases.getCustomerInfo();
  }

  /// Logout user from RevenueCat
  Future<CustomerInfo> logout() async {
    // Clear validation cache on logout
    _lastValidatedUserId = null;
    _lastValidatedTime = null;
    return await Purchases.logOut();
  }
}

@riverpod
RevenueCatService revenueCatService(Ref ref) {
  return RevenueCatService();
}
