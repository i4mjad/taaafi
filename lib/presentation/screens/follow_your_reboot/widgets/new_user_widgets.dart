import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';

import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';

void newUserDialog(BuildContext context, FollowYourRebootBloc bloc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.35,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: lightPrimaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Iconsax.calendar_tick,
                color: lightPrimaryColor,
                size: 32,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              AppLocalizations.of(context).translate('start-your-journy'),
              style: kHeadlineStyle.copyWith(
                  fontWeight: FontWeight.bold, color: lightPrimaryColor),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              AppLocalizations.of(context).translate('start-your-journy-p'),
              style: kBodyStyle.copyWith(height: 1.2),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    var selectedDate = await getDateTime(context);
                    await bloc
                        .createNewData(selectedDate)
                        .then((value) => Navigator.pop(context));
                  },
                  child: Container(
                    height: 80,
                    width: ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.5)),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('specific-day'),
                        style: kTitleSeconderyStyle,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await bloc
                        .createNewData(DateTime.now())
                        .then((value) => Navigator.pop(context));
                  },
                  child: Container(
                    height: 80,
                    width: ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12.5)),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('today'),
                        style:
                            kTitleSeconderyStyle.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      );
    },
  );
}

Future<DateTime> getDateTime(BuildContext context) async {
  return await showRoundedDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 1),
    lastDate: DateTime.now(),
    borderRadius: 16,
    fontFamily: 'DINNextLTArabic',
    height: MediaQuery.of(context).size.height / 2.5,
    theme: ThemeData(
      primaryColor: lightPrimaryColor,
    ),
  );
}

DateTime getToday() {
  return DateTime.now();
}
