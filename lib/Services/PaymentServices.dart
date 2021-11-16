import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaymentServices {
  static const _apiKey = 'BsKLbFbMxsauIzrGbFJAqEcCSTpoTraR';

  static Future<void> initPayment() async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(_apiKey);
  }

  static Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      return current == null ? [] : [current];
    } on PlatformException catch (e) {
      print(e.code);

      return [];
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } catch (e) {
      return false;
    }
  }
}
