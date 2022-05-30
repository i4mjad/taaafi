import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/about/about_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/presentation/Screens/account/account_screen.dart';

import 'package:reboot_app_3/presentation/Screens/home/home_screen.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class NavigationBar extends StatefulWidget {
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int _selectedIndex = 0;
  List<Widget> _pages = <Widget>[
    HomeScreen(),
    FollowYourRebootScreenAuthenticationWrapper(),
    // CommunityPage(),
    AccountScreenScreenAuthenticationWrapper(),
    AboutScreen(),
  ];

  void _onItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Center(
          child: _pages.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Iconsax.home),
              label: AppLocalizations.of(context).translate('home')),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.chart,
              ),
              label: AppLocalizations.of(context).translate('fyr')),
          // BottomNavigationBarItem(
          //     icon: Icon(
          //       Iconsax.people,
          //     ),
          //     label: AppLocalizations.of(context).translate('community')),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.personalcard,
              ),
              label: AppLocalizations.of(context).translate('account')),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.heart_tick,
              ),
              label: AppLocalizations.of(context).translate('about')),
        ],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: kSubTitlesSubsStyle.copyWith(
          color: primaryColor,
        ),
        unselectedLabelStyle:
            kSubTitlesSubsStyle.copyWith(color: mainGrayColor),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        iconSize: 22,
        currentIndex: _selectedIndex,
        onTap: _onItemTap,
      ),
    );
  }
}
