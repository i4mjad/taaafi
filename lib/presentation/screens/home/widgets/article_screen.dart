import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/data/models/Article.dart';

import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';

class ExploreContentPage extends StatelessWidget {
  ExploreContentPage({Key? key, required this.article}) : super(key: key);
  final ExploreContent article;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Column(
          children: [
            SizedBox(
              height: 8,
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
                              color: theme.primaryColor,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy hh:mm').format(
                                DateTime.parse(article.date as String),
                              ),
                              style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 10.5,
                                height: 1,
                                color: theme.primaryColor,
                              ),
                            ),
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
                              color: theme.primaryColor,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              article.author as String,
                              style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 10.5,
                                height: 1,
                                color: theme.primaryColor,
                              ),
                            ),
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
                            color: theme.primaryColor.withAlpha(20)),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.timer,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(article.timeToRead as String,
                                style: kSubTitlesSubsStyle.copyWith(
                                    fontSize: 10.5,
                                    height: 1,
                                    color: theme.primaryColor)),
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
                        children: [],
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
