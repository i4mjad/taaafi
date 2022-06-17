import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('welcome'),
          style: kSubTitlesStyle,
        ),
        SizedBox(
          height: 8,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.27,
              height: 150,
              decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(width: 0.25, color: Colors.green),
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //TODO - add bloc here
                  Text(
                    "24",
                    style: kPageTitleStyle.copyWith(
                      color: Colors.green,
                      fontSize: 35,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).translate('free-relapse-days'),
                    style: kSubTitlesStyle.copyWith(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Spacer(),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  height: 71,
                  width: MediaQuery.of(context).size.width * 0.60,
                  decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 0.25, color: Colors.brown)),
                  child: Center(
                    //TODO - add bloc here
                    child: Text(
                      "عدد الانتكاسات في ال30 يوم الماضية: " + "0",
                      style: kSubTitlesStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  height: 71,
                  width: MediaQuery.of(context).size.width * 0.60,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(width: 0.25, color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "عدد الأيام بدون إباحية منذ البداية: " + "0",
                      style: kSubTitlesStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
