import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class FollowUpSection extends StatelessWidget {
  const FollowUpSection({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 16, left: 16),
            child: Text(
                AppLocalizations.of(context).translate('current-streak') + " (TESTING)",
                style: kSubTitlesStyle),
          ),
          SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red, width: 0.25),


                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.center,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "12",
                              style: kPageTitleStyle.copyWith(
                                color: Colors.red,
                                fontSize: 35,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-relapse-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange, width: 0.25)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.center,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "12",
                              style: kPageTitleStyle.copyWith(
                                  color: Colors.orange),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-mast-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.purple, width: 0.25)

                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.center,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "2",
                              style: kPageTitleStyle.copyWith(
                                  color: Colors.purple),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-porn-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final DateTime now = DateTime.now();
                    final DateFormat formatter =
                    DateFormat('yyyy-MM-dd');
                    final String today = formatter.format(now);

                    changeDateEvent(today, context);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 16, left: 16),
                    child: Container(
                      width: (MediaQuery.of(context).size.width),
                      height: 60,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: .25,
                            blurRadius: 7,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('daily-follow-up'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 20,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void changeDateEvent(String date, BuildContext context) async {
    final trimedDate = date.trim();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
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
                      color: Colors.black12,
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trimedDate,
                      style: kPageTitleStyle.copyWith(fontSize: 26),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.black26,
                        size: 32,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('how-did-you-perform-in-this-day'),
                      style: kPageTitleStyle.copyWith(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //relapse
                    GestureDetector(
                      onTap: () {
                        print("Hello");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.red)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //success
                    GestureDetector(
                      onTap: () {
                        print("Hello");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.green)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 18,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //only porn
                    GestureDetector(
                      onTap: () {
                        print("hello cake");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.deepPurple)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.deepPurple,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //only mast
                    GestureDetector(
                      onTap: () {
                        print("donut");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.orangeAccent)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }
}

