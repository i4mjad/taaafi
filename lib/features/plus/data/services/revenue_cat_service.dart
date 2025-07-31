import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  /// Initialize RevenueCat
  Future<void> initialize({String? userId}) async {
    try {
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

      // If userId is provided, log in the user after configuration
      if (userId != null) {
        await Purchases.logIn(userId);
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
    return await Purchases.getCustomerInfo();
  }

  /// Get available offerings and packages
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// Purchase a specific package
  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  /// Restore previous purchases
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  /// Login user to RevenueCat
  Future<CustomerInfo> login(String userId) async {
    final result = await Purchases.logIn(userId);
    return result.customerInfo;
  }

  /// Logout user from RevenueCat
  Future<CustomerInfo> logout() async {
    return await Purchases.logOut();
  }
}

@riverpod
RevenueCatService revenueCatService(Ref ref) {
  return RevenueCatService();
}
