import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/notes/add_note_screen.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

AppBar appBarWithSettings(BuildContext context, String titleId) {
  return AppBar(
    backgroundColor: seconderyColor.withOpacity(0.2),
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle,
    ),
    iconTheme: IconThemeData(
      color: primaryColor,
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

AppBar notesAppBar(BuildContext context, String titleId) {
  return AppBar(
    backgroundColor: seconderyColor.withOpacity(0.2),
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle,
    ),
    iconTheme: IconThemeData(
      color: primaryColor,
    ),
    actions: [
      GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddNoteScreen()));
        },
        child: Container(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Icon(
            Iconsax.element_plus,
            color: primaryColor,
          ),
        ),
      )
    ],
  );
}

AppBar plainAppBar(BuildContext context, String titleId) {
  return AppBar(
    backgroundColor: seconderyColor.withOpacity(0.2),
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle,
    ),
    iconTheme: IconThemeData(
      color: primaryColor,
    ),
  );
}

AppBar noteAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: seconderyColor.withOpacity(0.2),
    elevation: 0,
    centerTitle: true,
    title: Text(
      title,
      style: kSubTitlesStyle,
    ),
    iconTheme: IconThemeData(
      color: primaryColor,
    ),
  );
}
