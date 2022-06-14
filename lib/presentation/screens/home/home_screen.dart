import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/widgets/content_screen.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
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
      backgroundColor: seconderyColor.withOpacity(0.2),
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
              WelcomeWidget(),
              SizedBox(
                height: 20,
              ),
              ExploreWidget(),
              SizedBox(
                height: 20,
              ),
              Ta3afiLiberaryWidget(),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Ta3afiLiberaryWidget extends StatelessWidget {
  const Ta3afiLiberaryWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).translate('nofap-content'),
          style: kSubTitlesStyle,
        ),
        SizedBox(
          height: 12,
        ),
        Ta3afiLiberaryCard(),
      ],
    );
  }
}

class ExploreWidget extends StatelessWidget {
  const ExploreWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 150,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor, width: 0.25),
        borderRadius: BorderRadius.circular(12.5),
      ),
    );
  }
}

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {},
        child: Text(
          'تابع محتوى التعافي',
          style: kTitleSeconderyStyle,
        ));
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
