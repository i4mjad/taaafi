import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert' show utf8;
import 'package:reboot_app_3/Services/BottomNavbar.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:reboot_app_3/Services/ContentLoadServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Localization.dart';
import 'package:chips_choice/chips_choice.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({Key key}) : super(key: key);

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  String lang;
  final TextEditingController searchTextEditor = TextEditingController();

  List<Content> appContent = [];
  List<Content> fillteredAppContent = [];

  List<String> selectedSubTypesList = [];
  List<String> selectedTypesList = [];

  String fixArbicText(String currptedText) {
    String text = utf8.decode(currptedText.codeUnits);
    return text;
  }

  void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  loadContent() async {
    await ContentServices.getContent().then((array) {
      List<Content> _temp = [];

      for (var item in array) {
        final temp = item.content;
        final fixedContent = Content(
          title: fixArbicText(temp.title),
          contentOwner: fixArbicText(temp.contentOwner),
          contentType: fixArbicText(temp.contentType),
          contentSubType: fixArbicText(temp.contentSubType),
          contentLanguage: fixArbicText(temp.contentLanguage),
        );
        _temp.add(fixedContent);
      }
      setState(() {
        appContent = _temp;
      });
    });
  }

  List<String> getContentTypes() {
    List<String> contentTypes = [];

    for (var item in appContent) {
      contentTypes.add(item.contentType);
    }

    return contentTypes.toSet().toList();
  }

  List<String> getContentSubTypes() {
    List<String> contentTypes = [];

    for (var item in appContent) {
      contentTypes.add(item.contentSubType);
    }

    return contentTypes.toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    getSelectedLocale();
    loadContent().then((value) {
      setState(() {
        fillteredAppContent = appContent;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: seconderyColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 40.0,
            left: 20.0,
            right: 20,
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context,
                      MaterialPageRoute(builder: (context) => NavigationBar()));
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
                          AppLocalizations.of(context)
                              .translate('nofap-content'),
                          style:
                              kPageTitleStyle.copyWith(height: 1, fontSize: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Row(
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
                        filterSearchResults(value);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Container(
                width: MediaQuery.of(context).size.width - 40,
                height: MediaQuery.of(context).size.height * 0.045,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showFilters();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Iconsax.document, size: 16, color: primaryColor),
                          SizedBox(width: 4),
                          Text(
                              AppLocalizations.of(context)
                                  .translate('search-filters'),
                              style: kSubTitlesStyle.copyWith(
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    VerticalDivider(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSubTypesList.clear();
                          selectedTypesList.clear();
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Iconsax.recovery_convert,
                              size: 16, color: primaryColor),
                          SizedBox(width: 4),
                          Text(
                              AppLocalizations.of(context)
                                  .translate('reset-fillters'),
                              style: kSubTitlesStyle.copyWith(
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (BuildContext context) {
                  if (appContent.length == 0) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width - 40,
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              AppLocalizations.of(context).translate("loading"),
                              style: kSubTitlesStyle.copyWith(
                                  color: primaryColor, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Expanded(
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
                                    itemCount: fillteredAppContent.length,
                                    padding: EdgeInsets.all(0),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return ContentCard(
                                          content: fillteredAppContent[index]);
                                    }),
                              );
                            })),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (modalContext, modalSetState) => Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('search-filters'),
                          style: kPageTitleStyle.copyWith(fontSize: 22),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.black26,
                            size: 28,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('content-category'),
                          style: kSubTitlesStyle,
                        ),
                      ],
                    ),
                    Container(
                      child: ChipsChoice<String>.multiple(
                        padding: EdgeInsets.all(0),
                        value: selectedSubTypesList,
                        choiceStyle: C2ChoiceStyle(
                            labelStyle: kSubTitlesStyle.copyWith(
                                fontSize: 16, height: 1, color: primaryColor),
                            borderColor: primaryColor,
                            color: primaryColor),
                        choiceActiveStyle: C2ChoiceStyle(),
                        onChanged: (val) {
                          modalSetState(() => selectedSubTypesList = val);
                          setState(() => selectedSubTypesList = val);
                        },
                        choiceItems: C2Choice.listFrom<String, String>(
                          source: getContentSubTypes(),
                          value: (i, v) => v,
                          label: (i, v) => v,
                          tooltip: (i, v) => v,
                        ),
                        wrapped: true,
                        alignment: WrapAlignment.start,
                        textDirection: this.lang == "ar"
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('content-type'),
                          style: kSubTitlesStyle,
                        ),
                      ],
                    ),
                    Container(
                      child: ChipsChoice<String>.multiple(
                        alignment: WrapAlignment.center,
                        choiceStyle: C2ChoiceStyle(
                            labelStyle: kSubTitlesStyle.copyWith(
                                fontSize: 16, height: 1, color: primaryColor),
                            borderColor: primaryColor,
                            color: primaryColor),
                        padding: EdgeInsets.all(0),
                        value: selectedTypesList,
                        onChanged: (val) {
                          modalSetState(() => selectedTypesList = val);
                          setState(() => selectedTypesList = val);
                        },
                        choiceItems: C2Choice.listFrom<String, String>(
                          source: getContentTypes(),
                          value: (i, v) => v,
                          label: (i, v) => v,
                          tooltip: (i, v) => v,
                        ),
                        wrapped: true,
                        placeholderStyle: kSubTitlesStyle,
                        textDirection: this.lang == "ar"
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            filtersService();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.42,
                            height: 50,
                            decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10.5),
                                border: Border.all(width: 0.25)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('apply-filters'),
                                  style: kSubTitlesStyle.copyWith(
                                      color: seconderyColor,
                                      height: 1,
                                      fontSize: 16),
                                )
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.42,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.5),
                              border:
                                  Border.all(color: primaryColor, width: 0.25)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('cancel'),
                                style: kSubTitlesStyle.copyWith(
                                    color: primaryColor,
                                    height: 1,
                                    fontSize: 16),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            ));
  }

  void filterSearchResults(String value) {
    List<Content> results = [];
    if (value.isEmpty &&
        (selectedTypesList.length != 0 || selectedSubTypesList.length != 0)) {
      results = appContent;
    } else {
      for (var i in results) {
        print(i.title);
      }
      results = appContent
          .where((content) => (content.title.toLowerCase().contains(value) ||
              content.contentOwner.toLowerCase().contains(value) ||
              content.contentType.toLowerCase().contains(value) ||
              content.contentSubType.toLowerCase().contains(value)))
          .toList();
    }

    setState(() {
      fillteredAppContent = results;
    });
  }

  void filtersService() {
    List<Content> results = [];

    if (selectedSubTypesList.length != 0 || selectedTypesList.length != 0) {
      results = appContent
          .where((content) =>
                  (selectedTypesList.contains(content.contentType) ||
                      selectedSubTypesList.contains(content.contentSubType))
              //here
              )
          .toList();
    }

    setState(() {
      fillteredAppContent = results;
    });
  }
}

// ignore: must_be_immutable
class ContentCard extends StatelessWidget {
  Content content;
  ContentCard({Key key, this.content}) : super(key: key);

  String fixArbicText(String currptedText) {
    String text = utf8.decode(currptedText.codeUnits);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launch(content.contentLink),
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
                          child: Icon(Iconsax.receipt),
                        )),
                    SizedBox(width: 10),
                    Flexible(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title,
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
                                Icon(
                                  Iconsax.user,
                                  color: primaryColor,
                                  size: 14,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  content.contentOwner,
                                  style: kSubTitlesStyle.copyWith(
                                      color: Colors.black45,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400),
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
                        child: Text(
                            AppLocalizations.of(context)
                                .translate(content.contentType),
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
                            color: Colors.purple.withAlpha(20)),
                        child: Text(content.contentSubType,
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 12, height: 1, color: Colors.purple)),
                      )
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black12),
                    child: Text(content.contentLanguage,
                        style: kSubTitlesSubsStyle.copyWith(
                            fontSize: 12, height: 1, color: Colors.black)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
