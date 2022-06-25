import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';

class WelcomeContent {
  IconData iconName;
  String title;
  String subtitle;

  WelcomeContent(this.iconName, this.title, this.subtitle);
}

var FAKE_CONTENT = [
  WelcomeContent(Iconsax.book, "كيف تبدأ؟", "دليل"),
  WelcomeContent(Iconsax.paperclip, "كيف تستفيد من التطبيق؟", "تعافي"),
  WelcomeContent(Iconsax.pen_close, "مصادر مهمة", "مصادر"),
];
