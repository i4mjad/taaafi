import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Screens/About/AboutScreen.dart';
import 'package:reboot_app_3/Screens/Account/Widgets/AccountScreen.dart';
import 'package:reboot_app_3/Shared/Constants.dart';
import 'package:reboot_app_3/Localization.dart';

import 'package:reboot_app_3/screens/Community/Community.dart';
import 'package:reboot_app_3/screens/Home/HomeScreen.dart';

class NavigationBar extends StatefulWidget {
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  int _selectedIndex = 0;
  List<Widget> _pages = <Widget>[
    HomeScreen(),
    CommunityPage(),
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
                Iconsax.people,
              ),
              label: AppLocalizations.of(context).translate('community')),
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
