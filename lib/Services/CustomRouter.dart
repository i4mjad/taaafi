import 'package:flutter/material.dart';
import 'package:reboot_app_3/Screens/Community/Community.dart';
import 'package:reboot_app_3/Services/BottomNavbar.dart';
import 'package:reboot_app_3/Services/RoutesName.dart';
import 'package:reboot_app_3/screens/About/AboutScreen.dart';
import 'package:reboot_app_3/screens/Account/AccountScreen.dart';
import 'package:reboot_app_3/screens/auth/LoginPage.dart';

import 'package:reboot_app_3/screens/FollowYourReboot/FollowYourRebootScreen.dart';
import 'package:reboot_app_3/screens/Home/HomeScreen.dart';
import 'package:reboot_app_3/screens/FollowYourReboot/Notes/NotesPage.dart';

class CustomRouter {
  static Route<dynamic> allRoutes(RouteSettings settings) {
    switch (settings.name) {
      case navbar:
        return MaterialPageRoute(builder: (_) => NavigationBar());
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
        return MaterialPageRoute(
            builder: (_) => CommunityPage());
      case notesPage:
        return MaterialPageRoute(builder: (_) => NotesScreen());
    }
    return MaterialPageRoute(builder: (_) => Container());
  }
}
