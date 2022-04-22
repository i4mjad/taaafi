import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/models/Content.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'dart:convert' show utf8;
import 'package:url_launcher/url_launcher.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  ContentCard({Key key, this.content}) : super(key: key);

  String fixArbicText(String currptedText) {
    String text = utf8.decode(currptedText.codeUnits);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        launch(content.contentLink);
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.archive_book,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentType,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: Colors.green)),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Iconsax.bill,
                            size: 18,
                            color: Colors.purple,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentSubType,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: Colors.purple)),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Iconsax.language_circle,
                            size: 18,
                            color: Colors.black,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentLanguage,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: Colors.black)),
                        ],
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
