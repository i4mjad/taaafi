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
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Show a ban snackbar with action to view details
void showBanSnackBar(
  BuildContext context,
  String message, {
  required VoidCallback onViewDetails,
  bool isPermanent = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(_banSnackBar(context, message,
      onViewDetails: onViewDetails, isPermanent: isPermanent));
}

SnackBar _banSnackBar(
  BuildContext context,
  String message, {
  required VoidCallback onViewDetails,
  bool isPermanent = false,
}) {
  final theme = AppTheme.of(context);
  final l10n = AppLocalizations.of(context);

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
    duration: const Duration(seconds: 5),
    shape: SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: 15,
        cornerSmoothing: 1,
      ),
      side: BorderSide(
        width: 2,
        color: theme.error[400]!,
      ),
    ),
    backgroundColor: theme.error[50],
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.shieldOff,
          color: theme.error[600],
          size: 24,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.translate('access-restricted'),
                style: TextStyles.body.copyWith(
                  color: theme.error[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyles.caption.copyWith(
                  color: theme.error[700],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.error[600],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onViewDetails,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.eye,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      l10n.translate('view-details'),
                      style: TextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
