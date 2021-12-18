import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:reboot_app_3/Model/Articles.dart';
import 'package:reboot_app_3/Model/Tutorial.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreScreen.dart';
import 'package:reboot_app_3/Screens/Home/CategoriesCard.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:reboot_app_3/screens/FollowYourReboot/FollowYourRebootScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String lang;

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }
  FirebaseFirestore database = FirebaseFirestore.instance;

  Future<List<Article>> getAtricles() async {
    final dataPath = database.collection("fl_content");
    List<Article> _articles = [];
    dataPath.snapshots().listen((data) async{
      for (var entry in data.docs) {
        if (entry["_fl_meta_"]["schema"] == "posts") {
          final newArticale = new Article(
            entry["title"],
            entry["date"].toString().substring(0, 10),
            entry["author"],
            entry["timeToRead"].toString(),
            entry["breif"],
            entry["postBody"],
          );
          _articles.add(newArticale);
        }
      }
    });

    return _articles;
  }
  Future<List<Tutorial>> getTutorials() async {
    final dataPath = database.collection("fl_content");
    List<Tutorial> _tutorials = [];
    dataPath.snapshots().listen((data) async {

      for (var entry in data.docs) {
        if (entry["_fl_meta_"]["schema"] == "tutorials") {

          final newTutorial = new Tutorial(
            entry["title"],
            entry["date"].toString().substring(0, 10),
            entry["author"],
            entry["body"],
          );
          _tutorials.add(newTutorial);
        }
      }
    });

    return _tutorials;
  }



  @override
  void initState() {
    super.initState();
    getSelectedLocale();
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate("welcome"),
                    style: kPageTitleStyle.copyWith(height: 1),
                  ),
                  GestureDetector(
                    onTap: () {
                      _changeLanguage();
                    },
                    child: Container(
                        padding: EdgeInsets.all(8),

                        child: Center(
                            child: Icon(
                              Platform.isIOS != true ? Icons.settings : CupertinoIcons.settings,
                              color: primaryColor,

                            )
                        ),

                    ),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('explore'),
                    style: kSubTitlesStyle,
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async{
                      var tutorialList = await getTutorials();
                      var articalesList = await getAtricles();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ExploreScreen(tutorialsList: tutorialList, articalsList: articalesList,)));
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width - 20,
                      height: 75,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: primaryColor.withOpacity(0.5), width: 0.25),
                          borderRadius: BorderRadius.circular(12.5)),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate("explore-p"),
                              style: kSubTitlesSubsStyle.copyWith(
                                  height: 1.25,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
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
                  GestureDetector(
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
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius:
                                                BorderRadius.circular(12.5)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'follow-your-reboot'),
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
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('nofap-content'),
                    style: kSubTitlesStyle,
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              CategoriesCards(),
              SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String languageCode = await prefs.getString("languageCode");

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Choose a Language",
                      style: kPageTitleStyle.copyWith(fontSize: 22),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "اختر اللغة المناسبة لك",
                      style: kPageTitleStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Arabic
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'ar');
                        final arLocale =
                            Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(this.context, arLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "العربية",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //English
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'en');
                        final enLocale =
                            Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(this.context, enLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "ِEnglish",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
              ],
            ),
          );
        });
  }
}
