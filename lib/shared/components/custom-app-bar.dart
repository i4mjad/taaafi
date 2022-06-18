import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

AppBar customAppBar(BuildContext context, String titleId) {
  return AppBar(
    backgroundColor: seconderyColor.withOpacity(0.2),
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle,
    ),
    iconTheme: IconThemeData(
      color: Colors.black, //change your color here
    ),
    actions: [
      GestureDetector(
        onTap: () {
          ChangeLanguageWidget.changeLanguage(context);
        },
        child: Container(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Center(
              child: Icon(
            Iconsax.setting,
            color: primaryColor,
          )),
        ),
      ),
    ],
  );
}
