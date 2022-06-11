import 'package:flutter/material.dart';
import 'package:reboot_app_3/Presentation/screens/about/about_screen.dart';
import 'package:reboot_app_3/presentation/screens/account/account_screen.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/screens/community/community_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/presentation/screens/home/home_screen.dart';
import 'package:reboot_app_3/shared/components/bottom_navbar.dart';

import 'routes_names.dart';
class CustomRouter {
  static Route<dynamic> allRoutes(RouteSettings settings) {
    switch (settings.name) {
      case navbar:
        return MaterialPageRoute(builder: (_) => BottomNavBar());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case followYourReboot:
        return MaterialPageRoute(
            builder: (_) => FollowYourRebootScreenAuthenticationWrapper());
      case accountRoute:
        return MaterialPageRoute(
            builder: (_) => AccountScreenScreenAuthenticationWrapper());
      case aboutRoute:
        return MaterialPageRoute(builder: (_) => AboutScreen());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case communityPage:
        return MaterialPageRoute(builder: (_) => CommunityPage());
    }
    return MaterialPageRoute(builder: (_) => Container());
  }
}
