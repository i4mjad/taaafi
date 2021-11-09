import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Screens/Home/%D9%90Explore/ExploreScreen.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:flutter/foundation.dart';
import 'package:reboot_app_3/Services/ContentLoadServices.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Localization.dart';

class ExploreContentScreen extends StatefulWidget {
  const ExploreContentScreen({Key key, @required this.contentType})
      : super(key: key);

  final String contentType;
  @override
  _ExploreContentScreenState createState() => _ExploreContentScreenState();
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

class _ExploreContentScreenState extends State<ExploreContentScreen> {
  String lang;

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  List<Content> contentList = [];
  List<Content> fillterdContentList = [];
  // ignore: unused_field
  final _debouncer = Debouncer(500);

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    getSelectedLocale();

    contentList.clear();
    fillterdContentList.clear();

    // setState(() {
    //   ContentServices.getMobileContent().then((APIContent) {
    //     setState(() {
    //       contentList = APIContent;
    //       fillterdContentList = contentList;
    //       isLoaded = true;
    //     });
    //   });
    // });
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
              children: [Text(widget.contentType, style: kPageTitleStyle)],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width - 40,
            height: 45,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(10.5)),
              color: mainGrayColor.withOpacity(0.5),
            ),
            child: TextField(
              enableSuggestions: false,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: primaryColor,
                ),
                border: InputBorder.none,
                hintText: AppLocalizations.of(context).translate('search'),
                hintStyle: kSubTitlesSubsStyle.copyWith(
                    fontSize: 16, color: primaryColor, height: 1.9),
                contentPadding: EdgeInsets.only(left: 12, right: 12),
              ),
              onChanged: (text) {},
            ),
          ),
        ],
      ),
    );
  }
}
