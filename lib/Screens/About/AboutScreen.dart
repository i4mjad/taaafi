import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
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
                      height: 40,
                    ),
                    Column(
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => launch("https://www.i4mjad.com"),
                                  child: Container(
                                    height: 55,
                                    width: (MediaQuery.of(context).size.width -
                                            40) *
                                        0.475,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.5),
                                        border: Border.all(color: primaryColor.withOpacity(0.5), width: 0.25)
                                    ),
                                    child: Center(
                                      child: Text(
                                          AppLocalizations.of(context).translate(
                                              'contact-us-through-this-channels'),
                                          style: kSubTitlesSubsStyle.copyWith(
                                              fontSize: 14,
                                              color: primaryColor,
                                              height: 1)),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    supportAppDevelopment();
                                  },
                                  child: Container(
                                    height: 55,
                                    width: (MediaQuery.of(context).size.width -
                                            40) *
                                        0.475,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: primaryColor.withOpacity(0.5), width: 0.25),
                                      borderRadius: BorderRadius.circular(12.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)
                                              .translate(
                                                  'support-app-development'),
                                          style: kSubTitlesSubsStyle.copyWith(
                                              fontSize: 14,
                                              color: primaryColor,
                                              height: 1)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],
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

  supportAppDevelopment() async {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(50)),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(50)),
                        child: Center(
                          child: Icon(
                            Iconsax.heart,
                            color: Colors.red,
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('support-app-development'),
                        style: kPageTitleStyle.copyWith(
                            fontSize: 24, color: primaryColor),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('support-app-development-p'),
                            style: kSubTitlesSubsStyle.copyWith(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  //small tip
                  GestureDetector(
                    onTap: () {
                      print('Small Tip');
                    },
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("🤍"),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('small-tip'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 14, color: primaryColor),
                                    )
                                  ],
                                ),
                                Spacer(),
                                Text(lang != 'ar' ? '\u0024 0.99' : '0.99 \u0024')
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  //midumn tip
                  GestureDetector(
                    onTap: () {
                      print('Midumn Tip');
                    },
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("💙"),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('mid-tip'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 14, color: primaryColor),
                                    )
                                  ],
                                ),
                                Spacer(),
                                Text(lang != 'ar' ? '\u0024 2.99' : '2.99 \u0024')
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  //high tip
                  GestureDetector(
                    onTap: () {
                      print('High Tip');
                    },
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("❤️"),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('high-tip'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 14, color: primaryColor),
                                    )
                                  ],
                                ),
                                Spacer(),
                                Text(lang != 'ar' ? '\u0024 6.99' : '6.99 \u0024')
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  //massive tip
                  GestureDetector(
                    onTap: () {
                      print('Massive Tip');
                    },
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("🖤"),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('massive-tip'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 14, color: primaryColor),
                                    )
                                  ],
                                ),
                                Spacer(),
                                Text(lang != 'ar' ? '\u0024 9.99' : '9.99 \u0024')
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  //subsctipob tip
                  GestureDetector(
                    onTap: () {
                      print('Monthly Tip');
                    },
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [primaryColor, accentColor]),
                              borderRadius: BorderRadius.circular(12.5),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("💚"),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('subscription-tip'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 14, color: Colors.white),
                                    )
                                  ],
                                ),
                                Spacer(),
                                Text(
                                  lang != 'ar' ? '\u0024 4.99' : '4.99 \u0024',
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,)
                ],
              ),
            ),
          );
        });
  }
}
