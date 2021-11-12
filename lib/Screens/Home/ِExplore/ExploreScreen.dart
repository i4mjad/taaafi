import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Model/Articles.dart';
import 'package:reboot_app_3/Model/Tutorial.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreSearchScreen.dart';
import 'package:reboot_app_3/Services/BottomNavbar.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Localization.dart';
import 'ArticalePage.dart';
import 'TutorialPage.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String lang;
  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  List<Article> articals = [];
  List<Tutorial> tutorials = [];

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
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [primaryColor, accentColor]),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20))),
              child: Padding(
                padding: EdgeInsets.only(top: 80.0, right: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NavigationBar()));
                      },
                      child: Icon(
                        lang != "ar"
                            ? CupertinoIcons.arrow_left_circle
                            : CupertinoIcons.arrow_right_circle,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: seconderyColor,
                                borderRadius: BorderRadius.circular(50)),
                            child: Icon(
                              Iconsax.microscope,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('explore'),
                            style: kPageTitleStyle.copyWith(
                                height: 1, fontSize: 28, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.only(right: 20.0, left: 20, top: 12, bottom: 12),
              child: Text(
                AppLocalizations.of(context).translate('tutorials'),
                style: kSubTitlesStyle,
              ),
            ),

            Container(
              height: MediaQuery.of(context).size.height * 0.15,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: lang == 'ar'
                    ? EdgeInsets.only(right: 20.0)
                    : EdgeInsets.only(left: 20.0),
                child: Row(
                  children: [
                    Expanded(child: Builder(builder: (context) {
                      return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          itemBuilder: (BuildContext context, int index) {
                            return TutorialsCard(
                              lang: lang,
                              title: "عنوان الشرح رقم  ${index}",
                            );
                          });
                    })),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExploreContentScreen(
                            contentType: AppLocalizations.of(context)
                                .translate('tutorials'))));
              },
              child: Padding(
                padding: EdgeInsets.only(right: 20, left: 20, top: 12),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: primaryColor.withOpacity(0.5), width: 0.25),
                      borderRadius: BorderRadius.circular(10.5)),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('explore-tutorials'),
                      style: kSubTitlesStyle.copyWith(
                          color: primaryColor, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0, left: 20),
              child: Text(
                AppLocalizations.of(context).translate('articles'),
                style: kSubTitlesStyle,
              ),
            ),
            SizedBox(
              height: 12,
            ),
            //post widget
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(right: 20, left: 20.0),
                child: Column(
                  children: [
                    Expanded(child: Builder(builder: (context) {
                      return ListView.builder(
                          scrollDirection: Axis.vertical,
                          padding: EdgeInsets.all(0),
                          itemCount: 3,
                          itemBuilder: (BuildContext context, int index) {
                            return PostWidget(
                              title: "عنوان المقال رقم  ${index}",
                            );
                          });
                    })),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExploreContentScreen(
                            contentType: AppLocalizations.of(context)
                                .translate('articles'))));
              },
              child: Padding(
                padding: EdgeInsets.only(right: 20, left: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 50,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [primaryColor, accentColor]),
                      borderRadius: BorderRadius.circular(12.5)),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('explore-articles'),
                      style: kSubTitlesStyle.copyWith(
                          color: seconderyColor, fontSize: 16),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TutorialsCard extends StatelessWidget {
  const TutorialsCard({
    Key key,
    @required this.lang,
    @required this.title,
  }) : super(key: key);

  final String lang;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TutorialPage(title: title)));
      },
      child: Padding(
        padding: lang != 'ar'
            ? EdgeInsets.only(right: 20.0)
            : EdgeInsets.only(left: 20.0),
        child: Container(
          padding: EdgeInsets.all(12),
          width: (MediaQuery.of(context).size.width - 40) / 3.5 - 4,
          decoration: BoxDecoration(
            border:
                Border.all(color: primaryColor.withOpacity(0.3), width: 0.25),
            borderRadius: BorderRadius.circular(12.5),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Align(
                  alignment:
                      lang == 'ar' ? Alignment.topRight : Alignment.topLeft,
                  child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: seconderyColor,
                          borderRadius: BorderRadius.circular(10.5)),
                      child: Icon(
                        Iconsax.subtitle,
                        color: Colors.black,
                        size: 22,
                      ))),
              Spacer(),
              Align(
                alignment:
                    lang == 'ar' ? Alignment.centerRight : Alignment.centerLeft,
                child: (Text(
                  title,
                  style: kSubTitlesStyle.copyWith(
                      fontSize: 12, color: primaryColor),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class PostWidget extends StatelessWidget {
  String title;
  PostWidget({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ArticlePage(title: title)));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: primaryColor.withOpacity(0.1))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(children: [
                    Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: seconderyColor,
                            borderRadius: BorderRadius.circular(12.5)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(Iconsax.note_2),
                        )),
                    SizedBox(width: 10),
                    Flexible(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: kSubTitlesStyle.copyWith(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال نص المقال "
                                            .substring(0, 75) +
                                        "...",
                                    style: kSubTitlesStyle.copyWith(
                                        color: Colors.black45,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    )
                  ]),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFF045C44).withOpacity(0.15)),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.calendar,
                              size: 16,
                              color: Color(0xFF045C44),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text("03/04/2021",
                                style: kSubTitlesSubsStyle.copyWith(
                                    fontSize: 10.5,
                                    height: 1,
                                    color: Color(0xFF045C44))),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFF75372D).withAlpha(20)),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.user_edit,
                              size: 16,
                              color: Color(0xFF75372D),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text("أمجد السليماني",
                                style: kSubTitlesSubsStyle.copyWith(
                                    fontSize: 10.5,
                                    height: 1,
                                    color: Color(0xFF75372D))),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
