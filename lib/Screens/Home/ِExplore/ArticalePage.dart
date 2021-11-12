import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:reboot_app_3/Model/Articles.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreScreen.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class ArticlePage extends StatefulWidget {
  Article articale;
  ArticlePage({Key key, this.articale}) : super(key: key);

  @override
  _ArticlePageState createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
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
      body: Padding(
        padding: EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context,
                    MaterialPageRoute(builder: (context) => ExploreScreen()));
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        lang != "ar"
                            ? CupertinoIcons.arrow_left_circle
                            : CupertinoIcons.arrow_right_circle,
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.articale.title,
                        style:
                            kPageTitleStyle.copyWith(height: 1, fontSize: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 4,
            ),
            Divider(
              thickness: 0.75,
            ),
            SizedBox(
              height: 4,
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
                            Text(widget.articale.postedAt,
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
                            Text(widget.articale.author,
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
                      Container(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: primaryColor.withAlpha(20)),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.timer,
                              size: 16,
                              color: primaryColor,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                                "${widget.articale.timeToRead} " +
                                    AppLocalizations.of(context)
                                        .translate("minutes"),
                                style: kSubTitlesSubsStyle.copyWith(
                                    fontSize: 10.5,
                                    height: 1,
                                    color: primaryColor)),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              thickness: 0.75,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                              child: Html(
                            data: widget.articale.body,
                            style: {
                              "body": Style(
                                  fontSize: FontSize(18.0),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DINNextLTArabic"),
                            },
                          ))
                        ],
                      ),
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
