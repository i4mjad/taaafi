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

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
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
    final theme = Theme.of(context);
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
          color: theme.primaryColor,
        ),
        backgroundColor: theme.bottomAppBarColor,
        unselectedLabelStyle:
            kSubTitlesSubsStyle.copyWith(color: mainGrayColor),
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        iconSize: 22,
        currentIndex: _selectedIndex,
        onTap: _onItemTap,
      ),
    );
  }
}

class HomeNavBar extends StatefulWidget {
  const HomeNavBar({Key key}) : super(key: key);

  @override
  State<HomeNavBar> createState() => _HomeNavBarState();
}

class _HomeNavBarState extends State<HomeNavBar> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoTabScaffold(

      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Iconsax.home),
              // label: AppLocalizations.of(context).translate('home'),
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.chart,
              ),
              // label: AppLocalizations.of(context).translate('fyr')
              ),
          // BottomNavigationBarItem(
          //     icon: Icon(
          //       Iconsax.people,
          //     ),
          //     label: AppLocalizations.of(context).translate('community')),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.personalcard,
              ),
              // label: AppLocalizations.of(context).translate('account'),
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Iconsax.heart_tick,
              ),
              // label: AppLocalizations.of(context).translate('about'),
          ),
        ],
        activeColor: theme.primaryColor,
        backgroundColor: theme.bottomAppBarColor,

      ),
      // tabBuilder: (BuildContext context, int index) {
      //
      // },

      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context){
              return CupertinoPageScaffold(child: HomeScreen(),);
            });
          case 1:
            return CupertinoTabView(builder: (context){
              return CupertinoPageScaffold(child: FollowYourRebootScreenAuthenticationWrapper(),);
            });
          case 2:
            return CupertinoTabView(builder: (context){
              return CupertinoPageScaffold(child: AccountScreenScreenAuthenticationWrapper(),);
            });
          case 3:
            return CupertinoTabView(builder: (context){
              return CupertinoPageScaffold(child: AboutScreen(),);
            });
          default:
            return CupertinoPageScaffold(child: HomeScreen(),);
        }
      },

    );
  }
}


