import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/Shared/Components/ChangeLocaleBottomSheet.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/widgets/content_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';

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
              Platform.isIOS != true ? Icons.settings : CupertinoIcons.settings,
              color: primaryColor,
            )),
          ),
        )
      ],
    );
  }
}

class Ta3afiLiberaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.5),
          border:
              Border.all(width: 0.25, color: primaryColor.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context).translate('porn-addiction-recovery-p'),
            style: kSubTitlesSubsStyle.copyWith(
                color: primaryColor, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12, left: 12, top: 30, bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message_edit,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.video,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.document,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.book,
                  color: primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ContentScreen()));
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("explore-content"),
                          style: kPageTitleStyle.copyWith(
                              fontSize: 14,
                              color: seconderyColor,
                              height: 1,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}

class FollowYouRebootHero extends StatelessWidget {
  const FollowYouRebootHero({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    FollowYourRebootScreenAuthenticationWrapper()));
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width - 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: primaryColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Lottie.asset(
                'asset/illustrations/home-anumation.json',
                width: MediaQuery.of(context).size.width - 40,
                height: MediaQuery.of(context).size.width - 40,
                repeat: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('follow-your-reboot-p'),
                    style: kSubTitlesSubsStyle.copyWith(
                        color: Colors.white, fontSize: 14),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: MediaQuery.of(context).size.width / 2,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12.5)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('follow-your-reboot'),
                                style: kPageTitleStyle.copyWith(
                                    fontSize: 18,
                                    color: seconderyColor,
                                    height: 1,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ))
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
