import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    key,
  }) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20.0,
                  left: 20.0,
                  right: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset("asset/illustrations/app-logo-about.svg",
                        height: MediaQuery.of(context).size.height * 0.175),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      AppLocalizations.of(context).translate("ta3afi"),
                      style: kPageTitleStyle.copyWith(
                        color: theme.primaryColor,
                        fontSize: 32,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      AppLocalizations.of(context).translate("about-ta3afi"),
                      style: kBodyStyle.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "${Platform.isIOS == true ? AppLocalizations.of(context).translate('version-number-ios') : AppLocalizations.of(context).translate('version-number-android')} • ${Platform.isIOS == true ? "iOS" : "Android"}",
                      style: kSubTitlesStyle.copyWith(
                          fontSize: 16,
                          height: 1,
                          color: primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 80,
                    ),
                    Container(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          launchUrl(Uri.parse('https://t.me/i4mjad'));
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width / 1.5),
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kShadowColor,
                                spreadRadius: .25,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 2), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('support'),
                                style: kTitleSeconderyStyle.copyWith(
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      AppLocalizations.of(context).translate('support-p'),
                      style: kBodyStyle,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
