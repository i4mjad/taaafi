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
      return ;
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
