import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/features/account/data/models/user_profile.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/account/presentation/update_user_profile_modal_sheet.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthService authService = ref.watch(authServiceProvider);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final theme = AppTheme.of(context);
    final customTheme = ref.watch(customThemeProvider);
    return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, 'account', false, true),
        body: userProfileState.when(
          data: (userProfile) {
            if (userProfile == null) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    UserDetailsWidget(userProfile),
                    verticalSpace(Spacing.points24),
                    Text(
                      AppLocalizations.of(context).translate('app-settings'),
                      style: TextStyles.h6,
                    ),
                    verticalSpace(Spacing.points8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        changeLanguage(context);
                      },
                      child: SettingsButton(
                        icon: LucideIcons.smartphone,
                        textKey: 'ui-settings',
                      ),
                    ),
                    verticalSpace(Spacing.points16),
                    Text(
                      AppLocalizations.of(context)
                          .translate('account-settings'),
                      style: TextStyles.h6,
                    ),
                    verticalSpace(Spacing.points8),
                    SettingsButton(
                      icon: LucideIcons.userCog,
                      textKey: 'delete-my-data',
                    ),
                    verticalSpace(Spacing.points8),
                    SettingsButton(
                      icon: LucideIcons.logOut,
                      textKey: 'log-out',
                      action: () async {
                        await authService.signOut(context, ref);
                      },
                    ),
                    verticalSpace(Spacing.points8),
                    GestureDetector(
                      onTap: () async {
                        //TODO: this should be selected based on the provider, for testing purposes we will use Google
                        await authService.reSignInWithGoogle(context);
                        await authService.deleteAccount(context, ref);
                      },
                      child: SettingsButton(
                        icon: LucideIcons.userX,
                        textKey: 'delete-my-account',
                        type: 'error',
                      ),
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
                    verticalSpace(Spacing.points8),
                    SettingsButton(
                      icon: LucideIcons.laptop,
                      textKey: 'contact-us-through-this-channels',
                    ),
                    verticalSpace(Spacing.points12),
                    Container(
                      width: MediaQuery.of(context).size.width - 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('sponsored-by'),
                            style: TextStyles.bodyLarge
                                .copyWith(color: theme.primary[600]),
                          ),
                          verticalSpace(Spacing.points8),
                          //TODO: update the text to be Awalim logo
                          Text(
                            'منصة عوالم',
                            style:
                                TextStyles.h4.copyWith(color: theme.warn[500]),
                          ),
                        ],
                      ),
                    ),
                    verticalSpace(Spacing.points12),
                  ],
                ),
              ),
            );
          },
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          loading: () => Center(child: CircularProgressIndicator()),
        ));
  }

  void changeLanguage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(builder: (context, ref, child) {
          final theme = AppTheme.of(context);
          final themeNotifier = ref.watch(customThemeProvider.notifier);
          return Container(
            color: theme.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(Spacing.points16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('ui-settings'),
                        style: TextStyles.h4.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(LucideIcons.xCircle),
                      )
                    ],
                  ),
                  verticalSpace(Spacing.points24),
                  Text(
                    AppLocalizations.of(context).translate('night-mode'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points12),
                  GestureDetector(
                    onTap: () {
                      themeNotifier.toggleTheme();
                      Navigator.of(context).pop();
                    },
                    child: WidgetsContainer(
                      padding: EdgeInsets.all(12),
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(color: theme.primary[100]!),
                      borderRadius: BorderRadius.circular(10.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.moon),
                          horizontalSpace(Spacing.points12),
                          Text(
                            themeNotifier.darkTheme == true
                                ? AppLocalizations.of(context).translate('off')
                                : AppLocalizations.of(context).translate('on'),
                            style: TextStyles.footnoteSelected
                                .copyWith(color: theme.grey[900], height: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points24),
                  Text(
                    AppLocalizations.of(context).translate('change-lang'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  CustomSegmentedButton(
                    options: [
                      SegmentedButtonOption(
                          value: 'arabic', translationKey: 'arabic'),
                      SegmentedButtonOption(
                          value: 'english', translationKey: 'english'),
                    ],
                    selectedOption: _getSelectedLocale(context, ref),
                    onChanged: (value) {
                      _updateThelocale(value, ref);
                      Navigator.of(context).pop();
                    },
                  ),
                  verticalSpace(Spacing.points16),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  _getSelectedLocale(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    if (locale?.languageCode == 'ar') {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    } else if (locale?.languageCode == 'en') {
      return SegmentedButtonOption(value: 'english', translationKey: 'english');
    } else {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    }
  }

  void _updateThelocale(SegmentedButtonOption value, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final localeNotifier = ref.watch(localeNotifierProvider.notifier);

    if (value.value == "arabic" && locale?.languageCode == 'en') {
      localeNotifier.toggleLocale();
    } else if (value.value == "english" && locale?.languageCode == 'ar') {
      localeNotifier.toggleLocale();
    }
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
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: action,
      child: WidgetsContainer(
        padding: EdgeInsets.all(14),
        backgroundColor: _getBackgroundColor(type, theme),
        borderRadius: BorderRadius.circular(10.5),
        borderSide: BorderSide(color: _getBorderColor(type, theme), width: 1),
        child: Row(
          children: [
            Icon(
              icon,
              color: _getTextColor(type, theme),
            ),
            horizontalSpace(Spacing.points8),
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
        return theme.primary[50] as Color;
    }
  }

  Color _getTextColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.warn[900] as Color;
      case 'error':
        return theme.error[900] as Color;
      case 'app':
        return theme.grey[50] as Color;
      default:
        return theme.grey[900] as Color;
    }
  }

  Color _getBorderColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.warn[50] as Color;
      case 'error':
        return theme.error[100] as Color;
      case 'app':
        return theme.primary[100] as Color;
      default:
        return theme.primary[100] as Color;
    }
  }
}

class UserDetailsWidget extends StatelessWidget {
  const UserDetailsWidget(
    this.userProfile, {
    super.key,
  });
  final UserProfile userProfile;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.grey[100],
                child: Icon(LucideIcons.user),
              ),
              horizontalSpace(Spacing.points16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile.displayName,
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    userProfile.email,
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    AppLocalizations.of(context).translate(userProfile.gender) +
                        " • " +
                        userProfile.age.toString() +
                        " " +
                        AppLocalizations.of(context).translate('years'),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                useSafeArea: true,
                isScrollControlled: true,
                useRootNavigator: true,
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => UpdateUserProfileModalSheet(),
              );
            },
            child: Icon(
              LucideIcons.edit,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
