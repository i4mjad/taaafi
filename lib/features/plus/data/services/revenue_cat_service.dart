import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_cat_service.g.dart';

class RevenueCatService {
  static const String _apiKeyIOS =
      'appl_YOUR_IOS_KEY_HERE'; // Replace with your iOS key
  static const String _apiKeyAndroid =
      'goog_YOUR_ANDROID_KEY_HERE'; // Replace with your Android key

  /// Initialize RevenueCat
  Future<void> initialize({String? userId}) async {
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
