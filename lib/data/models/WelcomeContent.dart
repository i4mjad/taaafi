import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';


class WelcomeContent {
  Icon icon;
  String title;
  String subtitle;

  WelcomeContent(this.icon, this.title, this.subtitle);
}

var FAKE_CONTENT = [
  WelcomeContent(Icon(Iconsax.book), "كيف تبدأ؟", "دليل"),
  WelcomeContent(Icon(Iconsax.paperclip), "كيف تستفيد من التطبيق؟", "تعافي"),
  WelcomeContent(Icon(Iconsax.pen_close), "مصادر مهمة؟", "مصادر"),
];