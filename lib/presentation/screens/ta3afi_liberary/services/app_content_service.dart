import 'dart:convert';

import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/models/Item.dart';

AppContentServices appContentServicesFromJson(String str) =>
    AppContentServices.fromJson(json.decode(str));

String appContentServicesToJson(AppContentServices data) =>
    json.encode(data.toJson());

class AppContentServices {
  AppContentServices({
    required this.items,
  });
  List<Item> items;

  factory AppContentServices.fromJson(Map<String, dynamic> json) =>
      AppContentServices(
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}
