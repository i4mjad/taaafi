import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';

class ExploreContent {
  Color bgColor;
  String title;
  Color txtColor;

  ExploreContent(this.bgColor, this.title, this.txtColor);
}

var FAKE_EXPLORE_CONTENT = [
  ExploreContent(lightPrimaryColor, "مقاطع مرئية", Colors.white),
  ExploreContent(accentColor, "إدمان العادة السرية", Colors.white),
  ExploreContent(Colors.amber, "ذم الهوى", Colors.black)
];
