import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';

//TODO: to be updated after the migeration from old account screen
//! RENAME THIS
class UpdatedAccountScreen extends ConsumerWidget {
  const UpdatedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: appBar(context, ref, 'account'),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UserDetailsWidget(),
              verticalSpace(Spacing.points24),
              Text(
                AppLocalizations.of(context).translate('app-settings'),
                style: TextStyles.h6,
              ),
              verticalSpace(Spacing.points8),
              SettingsButton(
                icon: LucideIcons.database,
                textKey: 'daily-notification-time',
              ),
              verticalSpace(Spacing.points4),
              SettingsButton(
                icon: LucideIcons.smartphone,
                textKey: 'ui-settings',
              ),
              verticalSpace(Spacing.points16),
              Text(
                AppLocalizations.of(context).translate('account-settings'),
                style: TextStyles.h6,
              ),
              verticalSpace(Spacing.points8),
              SettingsButton(
                icon: LucideIcons.userCog,
                textKey: 'delete-my-data',
              ),
              verticalSpace(Spacing.points4),
              SettingsButton(
                icon: LucideIcons.logOut,
                textKey: 'log-out',
                action: () {
                  authRepository.signOut();
                },
              ),
              verticalSpace(Spacing.points4),
              SettingsButton(
                icon: LucideIcons.userX,
                textKey: 'delete-my-account',
                type: 'error',
              ),
              verticalSpace(Spacing.points16),
              Text(
                AppLocalizations.of(context).translate('about-app'),
                style: TextStyles.h6,
              ),
              verticalSpace(Spacing.points8),
              SettingsButton(
                icon: LucideIcons.heart,
                textKey: 'version-number',
                type: 'app',
              ),
              verticalSpace(Spacing.points4),
              SettingsButton(
                icon: LucideIcons.laptop,
                textKey: 'contact-us-through-this-channels',
              ),
              verticalSpace(Spacing.points4),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  final IconData icon;
  final String textKey;
  final String? type;
  final VoidCallback? action;
  const SettingsButton(
      {super.key,
      required this.icon,
      required this.textKey,
      this.type,
      this.action});

  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    return GestureDetector(
      onTap: action,
      child: WidgetsContainer(
        padding: EdgeInsets.all(12),
        backgroundColor: _getBackgroundColor(type, theme),
        borderRadius: BorderRadius.circular(10.5),
        borderSide: BorderSide(color: _getBorderColor(type, theme), width: 1),
        child: Row(
          children: [
            Icon(
              icon,
              color: _getTextColor(type, theme),
            ),
            horizontalSpace(Spacing.points16),
            Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyles.footnote
                  .copyWith(color: _getTextColor(type, theme)),
            )
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.warn[50] as Color;
      case 'error':
        return theme.error[50] as Color;
      case 'app':
        return theme.primary[600] as Color;
      default:
        return theme.grey[50] as Color;
    }
  }

  Color _getTextColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.warn[600] as Color;
      case 'error':
        return theme.error[600] as Color;
      case 'app':
        return theme.primary[50] as Color;
      default:
        return theme.grey[900] as Color;
    }
  }

  Color _getBorderColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.warn[100] as Color;
      case 'error':
        return theme.error[100] as Color;
      case 'app':
        return theme.primary[50] as Color;
      default:
        return theme.grey[100] as Color;
    }
  }
}

class UserDetailsWidget extends StatelessWidget {
  const UserDetailsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    return WidgetsContainer(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(16),
      backgroundColor: theme.primary[50],
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: theme.primary[100]!,
        width: 1.0,
      ),
      cornerSmoothing: 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.grey[100],
            child: Icon(
              LucideIcons.user,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "أمجد خلفان",
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              verticalSpace(Spacing.points4),
              Text(
                "akalsulimani@gmail.com",
                style: TextStyles.caption.copyWith(color: theme.grey[600]),
              ),
              verticalSpace(Spacing.points4),
              Text(
                " ذكر " + "•" + " 26 سنة " + "•" + " مسجل منذ أغسطس  2022 ",
                style: TextStyles.caption.copyWith(color: theme.grey[600]),
              ),
            ],
          ),
          Icon(
            LucideIcons.edit,
            size: 16,
          )
        ],
      ),
    );
  }
}
