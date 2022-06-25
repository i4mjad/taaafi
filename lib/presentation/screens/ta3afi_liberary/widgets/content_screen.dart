import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert' show utf8;
import 'package:chips_choice/chips_choice.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/models/Content.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/services/content_load_services.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';

import 'content_card.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({Key key}) : super(key: key);

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String lang;
  final TextEditingController searchTextEditor = TextEditingController();

  List<Content> appContent = [];
  List<Content> fillteredAppContent = [];

  List<String> selectedSubTypesList = [];
  List<String> selectedTypesList = [];
  List<String> selectedLanuguagesList = [];

  List<String> lanuguagesList = ["عربي", "English"];

  String fixArbicText(String currptedText) {
    String text = utf8.decode(currptedText.codeUnits);
    return text;
  }

  loadContent() async {
    await ContentServices.getContent().then((array) {
      List<Content> _temp = [];

      for (var item in array) {
        final temp = item.content;
        final fixedContent = Content(
          title: fixArbicText(temp.title),
          contentOwner: fixArbicText(temp.contentOwner),
          contentLink: temp.contentLink,
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
    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });

    fillteredAppContent.clear();
    appContent.clear();
    loadContent().then((value) {
      setState(() {
        fillteredAppContent = appContent;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBarWithSettings(context, "nofap-content"),
      body: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20.0,
          right: 20,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3), width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(10.5)),
                    color: theme.cardColor,
                  ),
                  child: TextField(
                    controller: searchTextEditor,
                    enableSuggestions: true,
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w400,
                        color: theme.hintColor),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      hintText:
                          AppLocalizations.of(context).translate('search'),
                      hintStyle: kSubTitlesSubsStyle.copyWith(
                        fontSize: 14,
                        color: theme.hintColor,
                        height: 1.75,
                      ),
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
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showFilters();
              },
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                height: MediaQuery.of(context).size.height * 0.045,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.all(
                    color: (selectedSubTypesList.length > 0 ||
                            selectedSubTypesList.length > 0 ||
                            selectedLanuguagesList.length > 0)
                        ? Colors.green
                        : theme.primaryColor,
                    width: (selectedSubTypesList.length > 0 ||
                            selectedSubTypesList.length > 0 ||
                            selectedLanuguagesList.length > 0)
                        ? 0.75
                        : 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.document,
                            size: 16, color: theme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                            AppLocalizations.of(context)
                                .translate('search-filters'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 14,
                                color: theme.primaryColor,
                                height: 1,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                ),
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
                                color: lightPrimaryColor, fontSize: 18),
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
    );
  }

  void _showFilters() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          final theme = Theme.of(context);
          return StatefulBuilder(
            builder: (modalContext, modalSetState) => SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                color: theme.scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 5,
                          width: MediaQuery.of(context).size.width * 0.1,
                          decoration: BoxDecoration(
                              color: mainGrayColor,
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
                          style: kPageTitleStyle.copyWith(
                              fontSize: 22, color: theme.primaryColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                          },
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: mainGrayColor,
                            size: 28,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('content-category'),
                          style: kSubTitlesStyle.copyWith(
                              fontSize: 16, color: theme.hintColor),
                        ),
                      ],
                    ),
                    Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: ChipsChoice<String>.multiple(
                              padding: EdgeInsets.all(0),
                              value: selectedSubTypesList,
                              choiceStyle: C2ChoiceStyle(
                                labelStyle: kSubTitlesStyle.copyWith(
                                    fontSize: 10.5,
                                    height: 1,
                                    color: lightPrimaryColor,
                                    fontWeight: FontWeight.w400),
                                borderColor: theme.primaryColor,
                                color: theme.cardColor,
                              ),
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
                              textDirection: this.lang == "ar"
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('content-type'),
                          style: kSubTitlesStyle.copyWith(
                              fontSize: 16, color: theme.hintColor),
                        ),
                      ],
                    ),
                    Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: ChipsChoice<String>.multiple(
                              alignment: WrapAlignment.start,
                              choiceStyle: C2ChoiceStyle(
                                  labelStyle: kSubTitlesStyle.copyWith(
                                      fontSize: 10.5,
                                      height: 1,
                                      color: lightPrimaryColor,
                                      fontWeight: FontWeight.w400),
                                  borderColor: theme.primaryColor,
                                  color: theme.primaryColor),
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
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('content-language'),
                          style: kSubTitlesStyle.copyWith(
                            fontSize: 16,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: ChipsChoice<String>.multiple(
                              alignment: WrapAlignment.start,
                              choiceStyle: C2ChoiceStyle(
                                  labelStyle: kSubTitlesStyle.copyWith(
                                      fontSize: 10.5,
                                      height: 1,
                                      color: lightPrimaryColor,
                                      fontWeight: FontWeight.w400),
                                  borderColor: theme.primaryColor,
                                  color: theme.primaryColor),
                              padding: EdgeInsets.all(0),
                              value: selectedLanuguagesList,
                              onChanged: (val) {
                                modalSetState(
                                    () => selectedLanuguagesList = val);
                                setState(() => selectedLanuguagesList = val);
                              },
                              choiceItems: C2Choice.listFrom<String, String>(
                                source: lanuguagesList,
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
                        ],
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
                            HapticFeedback.mediumImpact();
                            filtersService();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(10.5),
                              border: Border.all(
                                  width: 0.25, color: theme.primaryColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('apply-filters'),
                                  style: kSubTitlesStyle.copyWith(
                                      color: theme.scaffoldBackgroundColor,
                                      height: 1,
                                      fontSize: 16),
                                )
                              ],
                            ),
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
            ),
          );
        });
  }

  void filterSearchResults(String value) {
    List<Content> results = [];
    if (value.isEmpty) {
      results = appContent;
      if (value.isEmpty &&
          (selectedTypesList.length > 0 ||
              selectedSubTypesList.length > 0 ||
              selectedLanuguagesList.length > 0)) {
        results = appContent
            .where((content) =>
                selectedTypesList.contains(content.contentType) ||
                selectedSubTypesList.contains(content.contentSubType) ||
                selectedLanuguagesList.contains(content.contentLanguage))
            .toList();
      }
    } else {
      results = appContent
          .where((content) =>
              (content.title.toLowerCase().contains(value) ||
                  content.contentOwner.toLowerCase().contains(value) ||
                  content.contentType.toLowerCase().contains(value) ||
                  content.contentSubType.toLowerCase().contains(value)) &&
              (selectedTypesList.contains(content.contentType) ||
                  selectedSubTypesList.contains(content.contentSubType) ||
                  selectedLanuguagesList.contains(content.contentLanguage)))
          .toList();
    }

    setState(() {
      fillteredAppContent = results;
    });
  }

  void filtersService() {
    List<Content> results = [];
    if (selectedSubTypesList.length != 0 ||
        selectedTypesList.length != 0 ||
        selectedLanuguagesList.length != 0) {
      results = appContent
          .where((content) =>
                  (selectedTypesList.contains(content.contentType) ||
                      selectedSubTypesList.contains(content.contentSubType) ||
                      selectedLanuguagesList.contains(content.contentLanguage))

              //here
              )
          .toList();
    } else {
      setState(() {
        loadContent().then((value) {
          setState(() {
            fillteredAppContent = appContent;
          });
        });
      });
    }

    setState(() {
      fillteredAppContent = results;
    });
  }
}
