import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  @override
  void initState() {
    super.initState();
    getSelectedLocale();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: seconderyColor,
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
                        height: MediaQuery.of(context).size.height * 0.2),
                    Text(
                      AppLocalizations.of(context).translate("ta3afi"),
                      style: kPageTitleStyle.copyWith(
                          color: primaryColor, fontSize: 32),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      AppLocalizations.of(context).translate("about-ta3afi"),
                      style: kSubTitlesSubsStyle.copyWith(
                          color: Colors.black.withOpacity(0.5)),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        InkWell(
                          onTap: () => launch("https://www.i4mjad.com"),
                          child: Container(
                            height: 55,
                            width: MediaQuery.of(context).size.width - 40,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12.5),
                                border: Border.all(
                                    color:
                                        primaryColor.withOpacity(0.5),
                                    width: 0.25)),
                            child: Center(
                              child: Text(
                                  AppLocalizations.of(context).translate(
                                      'contact-us-through-this-channels'),
                                  style: kSubTitlesSubsStyle.copyWith(
                                      fontSize: 14,
                                      color: primaryColor,
                                      height: 1)

                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12,),
                        Text(
                            lang == 'ar' ? 'إذا استفدت من التطبيق, اذكُر والدي - رحمه الله - بدعوة' : '',
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 12,
                                color: accentColor.withOpacity(0.7),
                                height: 1

                            )
                        ),
                      ],
                    ),
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
