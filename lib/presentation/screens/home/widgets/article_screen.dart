import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';

class ArticlePage extends StatelessWidget {
  ArticlePage({Key key, this.title}) : super(key: key);
  String title;
  String longText =
      "هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. هذا نص طويل جدا جدا لدرجة أنه يجب أن يتخطى حجم شاشة الجهاز الحالي. ";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBarWithCustomTitle(context, title),
      body: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Column(
          children: [
            SizedBox(
              height: 4,
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
                              color: theme.primaryColor,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              "28/08/2022",
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
                              "أمجد السليماني",
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
                            Text("5 دقائق",
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
                        children: [
                          Flexible(
                              child: Text(
                            longText,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.5),
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
