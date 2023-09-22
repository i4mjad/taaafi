import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

import '../constants/textstyles_constants.dart';

void getSnackBar(BuildContext context, String messageId) {
  ScaffoldMessenger.of(context)
      .showSnackBar(customSnackBar(context, messageId));
}

void getSystemSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(systemSnackBar(context, message));
}

SnackBar customSnackBar(BuildContext context, String messageId) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: lightPrimaryColor, width: 0.5),
      borderRadius: BorderRadius.circular(12.5),
    ),
    backgroundColor: Color(0xFFe8eeef),
    content: Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Iconsax.tick_circle,
            color: lightPrimaryColor,
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              AppLocalizations.of(context).translate(messageId),
              style: kSubTitlesStyle.copyWith(
                  color: lightPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

SnackBar systemSnackBar(BuildContext context, String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: lightPrimaryColor, width: 0.5),
      borderRadius: BorderRadius.circular(12.5),
    ),
    backgroundColor: Color(0xFFe8eeef),
    content: Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Iconsax.info_circle,
            color: lightPrimaryColor,
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              message,
              style: kSubTitlesStyle.copyWith(
                  color: lightPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}
