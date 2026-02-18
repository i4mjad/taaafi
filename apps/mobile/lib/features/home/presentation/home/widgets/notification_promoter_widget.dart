import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class NotificationPromoterWidget extends ConsumerWidget {
  const NotificationPromoterWidget({super.key});

  Future<void> _handleNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _handleNotificationSettings,
        child: WidgetsContainer(
          borderRadius: BorderRadius.circular(16),
          backgroundColor: theme.success[50],
          borderSide: BorderSide(
            color: theme.success[200]!,
            width: 0.5,
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bellRing,
                color: theme.success[900],
                // size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .translate('notification-promotion'),
                  style: TextStyles.footnote
                      .copyWith(color: theme.grey[600], height: 1.4),
                ),
              ),
              horizontalSpace(Spacing.points4),
              GestureDetector(
                onTap: _handleNotificationSettings,
                child: Text(
                  AppLocalizations.of(context).translate('enable'),
                  style: TextStyles.smallBold.copyWith(
                    color: theme.success[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
