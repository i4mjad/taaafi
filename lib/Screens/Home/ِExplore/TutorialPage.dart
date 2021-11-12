import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:reboot_app_3/Model/Tutorial.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreScreen.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class TutorialPage extends StatefulWidget {
  Tutorial item;

  TutorialPage({Key key, this.item}) : super(key: key);

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  String lang;

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  String longText =
      "هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. ";

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
                        widget.item.title,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green.withOpacity(0.2)),
                        child: Text(widget.item.postedAt,
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 12, height: 1, color: Colors.green)),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: primaryColor.withAlpha(20)),
                        child: Text(widget.item.author,
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 12, height: 1, color: primaryColor)),
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
                            data: widget.item.body,
                            style: {
                              "body": Style(fontFamily: "DINNextLTArabic"),
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
