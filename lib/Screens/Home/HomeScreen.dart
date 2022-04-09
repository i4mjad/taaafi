import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Shared/Components/ChangeLocaleBottomSheet.dart';
import 'package:reboot_app_3/Shared/Localization.dart';
import 'package:reboot_app_3/Screens/Home/Ta3afiLiberaryCard.dart';
import 'package:reboot_app_3/Shared/Constants.dart';
import 'package:reboot_app_3/Shared/LocalizationServices.dart';
import 'Widgets/FollowYouRebootHero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String lang;

  @override
  void initState() {
    super.initState();

    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: seconderyColor,
      body: Padding(
        padding: EdgeInsets.only(top: 100.0, left: 20.0, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TobBar(),
              SizedBox(
                height: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    AppLocalizations.of(context)
                        .translate("follow-your-reboot"),
                    style: kSubTitlesStyle.copyWith(height: 1),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  FollowYouRebootHero(),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('nofap-content'),
                    style: kSubTitlesStyle,
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Ta3afiLiberaryCard(),
              SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TobBar extends StatelessWidget {
  const TobBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).translate("welcome"),
          style: kPageTitleStyle.copyWith(height: 1),
        ),
        GestureDetector(
          onTap: () {
            ChangeLanguageWidget.changeLanguage(context);
          },
          child: Container(
            padding: EdgeInsets.all(8),
            child: Center(
                child: Icon(
              Platform.isIOS != true
                  ? Icons.settings
                  : CupertinoIcons.settings,
              color: primaryColor,
            )),
          ),
        )
      ],
    );
  }
}

