import 'dart:convert';

import 'package:reboot_app_3/Screens/Ta3afiLiberary/Models/Item.dart';

AppContentServices appContentServicesFromJson(String str) =>
    AppContentServices.fromJson(json.decode(str));

String appContentServicesToJson(AppContentServices data) =>
    json.encode(data.toJson());

class AppContentServices {
  AppContentServices({
    this.items,
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
