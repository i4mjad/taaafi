import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

void getSnackBar(BuildContext context, String messageId) {
  ScaffoldMessenger.of(context)
      .showSnackBar(customSnackBar(context, messageId));
}

void getErrorSnackBar(BuildContext context, String messageId) {
  ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(context, messageId));
}

void getSystemSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(systemSnackBar(context, message));
}

SnackBar errorSnackBar(BuildContext context, String messageId) {
  final theme = AppTheme.of(context);
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

SnackBar customSnackBar(BuildContext context, String messageId) {
  final theme = AppTheme.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: theme.primary[100]!, width: 0.5),
      borderRadius: BorderRadius.circular(12.5),
    ),
    backgroundColor: Color(0xFFe8eeef),
    content: Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.check,
            color: theme.primary[600]!,
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              AppLocalizations.of(context).translate(messageId),
              style: TextStyles.caption.copyWith(
                color: theme.primary[600],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

SnackBar systemSnackBar(BuildContext context, String message) {
  final theme = AppTheme.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: theme.primary[100]!, width: 0.5),
      borderRadius: BorderRadius.circular(12.5),
    ),
    backgroundColor: Color(0xFFe8eeef),
    content: Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.check,
            color: theme.primary[600]!,
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              message,
              style: TextStyles.caption.copyWith(
                color: theme.primary[600]!,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
