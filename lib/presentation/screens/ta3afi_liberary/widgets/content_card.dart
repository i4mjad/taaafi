import 'dart:core';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/models/Content.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'dart:convert' show utf8;
import 'package:url_launcher/url_launcher.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  ContentCard({Key? key, required this.content}) : super(key: key);

  String fixArbicText(String currptedText) {
    String text = utf8.decode(currptedText.codeUnits);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        launchUrl(Uri.parse(content.contentLink!));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.cardColor,
            border: Border.all(color: lightPrimaryColor.withOpacity(0.1))),
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
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12.5)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            Iconsax.receipt,
                            color: theme.primaryColor,
                          ),
                        )),
                    SizedBox(width: 10),
                    Flexible(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title as String,
                              style: kSubTitlesStyle.copyWith(
                                  color: theme.primaryColor,
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
                                  color: theme.primaryColor,
                                  size: 14,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  content.contentOwner as String,
                                  style: kSubTitlesStyle.copyWith(
                                      color: theme.hintColor.withOpacity(0.7),
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
                            color: mainBlueColor,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentType as String,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: theme.primaryColor)),
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
                            color: mainBlueColor,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentSubType as String,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: theme.primaryColor)),
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
                            color: mainBlueColor,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(content.contentLanguage as String,
                              style: kSubTitlesSubsStyle.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  color: theme.primaryColor)),
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
