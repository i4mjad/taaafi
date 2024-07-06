import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

import '../constants/textstyles_constants.dart';

void getSnackBar(BuildContext context, String messageId,
    [String extraText = ""]) {
  ScaffoldMessenger.of(context)
      .showSnackBar(customSnackBar(context, messageId, extraText));
}

void getErrorSnackBar(BuildContext context, String messageId) {
  ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(context, messageId));
}

void getSystemSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(systemSnackBar(context, message));
}

SnackBar errorSnackBar(BuildContext context, String messageId) {
  final theme = CustomThemeInherited.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: theme.error[200]!,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(10.5),
    ),
    backgroundColor: theme.error[50],
    content: Container(
      padding: EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: theme.error[600],
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              AppLocalizations.of(context).translate(messageId),
              style: TextStyles.caption.copyWith(
                color: theme.error[600],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

SnackBar customSnackBar(BuildContext context, String messageId,
    [String extraText = ""]) {
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
              AppLocalizations.of(context).translate(messageId) + extraText,
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
