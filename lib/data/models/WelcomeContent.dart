import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';

class WelcomeContent {
  Icon icon;
  String title;
  String subtitle;

  WelcomeContent(this.icon, this.title, this.subtitle);
}

var FAKE_CONTENT = [
  WelcomeContent(
      Icon(
        Iconsax.book,
        size: 16,
      ),
      "كيف تبدأ؟",
      "دليل"),
  WelcomeContent(
      Icon(
        Iconsax.paperclip,
        size: 16,
      ),
      "كيف تستفيد من التطبيق؟",
      "تعافي"),
  WelcomeContent(
      Icon(
        Iconsax.pen_close,
        size: 16,
      ),
      "مصادر مهمة",
      "مصادر"),
];
