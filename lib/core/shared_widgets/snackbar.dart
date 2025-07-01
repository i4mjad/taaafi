import 'package:figma_squircle/figma_squircle.dart';
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
  ScaffoldMessenger.of(context)
      .showSnackBar(_errorSnackBar(context, messageId));
}

void getSuccessSnackBar(BuildContext context, String messageId) {
  ScaffoldMessenger.of(context)
      .showSnackBar(_successSnackBar(context, messageId));
}

void getSystemSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(systemSnackBar(context, message));
}

SnackBar _errorSnackBar(BuildContext context, String messageId) {
  final theme = AppTheme.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 15,
        cornerSmoothing: 1,
      ),
      side: BorderSide(
        width: 2,
        color: theme.error[300]!,
      ),
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
                color: theme.error[900],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

SnackBar _successSnackBar(BuildContext context, String messageId) {
  final theme = AppTheme.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 15,
        cornerSmoothing: 1,
      ),
      side: BorderSide(
        width: 2,
        color: theme.success[300]!,
      ),
    ),
    backgroundColor: theme.backgroundColor,
    content: Container(
      padding: EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkSquare,
            color: theme.success[600],
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          Flexible(
            child: Text(
              AppLocalizations.of(context).translate(messageId),
              style: TextStyles.caption.copyWith(
                color: theme.success[600],
                height: 1.5,
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
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 15,
        cornerSmoothing: 1,
      ),
      side: BorderSide(
        width: 2,
        color: theme.primary[300]!,
      ),
    ),
    backgroundColor: theme.primary[50],
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
                color: theme.grey[900],
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
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 15,
        cornerSmoothing: 1,
      ),
      side: BorderSide(
        width: 2,
        color: theme.primary[300]!,
      ),
    ),
    backgroundColor: theme.primary[50],
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
