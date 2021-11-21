import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Model/Articles.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreScreen.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Localization.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({Key key, @required this.articlesList})
      : super(key: key);

  final List<Article> articlesList;
  @override
  _ArticlesScreenState createState() => _ArticlesScreenState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer(this.milliseconds);

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  String lang;

  final TextEditingController searchTextEditor = TextEditingController();

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  List<Article> fillterdContentList = [];
  // ignore: unused_field
  final _debouncer = Debouncer(500);

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    getSelectedLocale();

    setState(() {
      fillterdContentList = widget.articlesList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: seconderyColor,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 80.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExploreScreen()));
                  },
                  child: Icon(
                    lang != "ar"
                        ? CupertinoIcons.arrow_left_circle
                        : CupertinoIcons.arrow_right_circle,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Row(
              children: [
                Text(AppLocalizations.of(context).translate("articles"),
                    style: kPageTitleStyle)
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: primaryColor.withOpacity(0.3), width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(10.5)),
                    color: mainGrayColor.withOpacity(0.5),
                  ),
                  child: TextField(
                    controller: searchTextEditor,
                    enableSuggestions: true,
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 14, height: 1, fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: Colors.grey.withOpacity(0.8),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      hintText:
                          AppLocalizations.of(context).translate('search'),
                      hintStyle: kSubTitlesSubsStyle.copyWith(
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.8),
                          height: 1.75),
                      contentPadding: EdgeInsets.only(left: 12, right: 12),
                    ),
                    onChanged: (value) {
                      _debouncer.run(() {
                        setState(() {
                          fillterdContentList = widget.articlesList
                              .where((content) => (content.title
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  content.author
                                      .toLowerCase()
                                      .contains(value.toLowerCase())))
                              .toList();
                        });
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              child: Column(
                children: [
                  Expanded(child: Builder(builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: 20.0,
                      ),
                      child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          padding: EdgeInsets.all(0),
                          itemCount: fillterdContentList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 20.0, left: 20),
                              child: PostWidget(
                                articale: fillterdContentList[index],
                              ),
                            );
                          }),
                    );
                  })),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
