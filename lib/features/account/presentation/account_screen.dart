import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/app_review/app_review.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/account/data/models/user_profile.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/account/presentation/update_user_profile_modal_sheet.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
            return Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.all(14),
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
                      GestureDetector(
                        onTap: () {
                          unawaited(ref
                              .read(analyticsFacadeProvider)
                              .trackUserResetDataStarted());

                          _showResetDataDialog(context, ref);
                        },
                        child: SettingsButton(
                          icon: LucideIcons.userCog,
                          textKey: 'delete-my-data',
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      SettingsButton(
                        icon: LucideIcons.logOut,
                        textKey: 'log-out',
                        action: () async {
                          await Sentry.configureScope(
                            (scope) => scope.setUser(null),
                          );
                          await authService.signOut(context, ref);
                          getSuccessSnackBar(
                              context, 'logged-out-successfully');
                        },
                      ),
                      verticalSpace(Spacing.points8),
                      GestureDetector(
                        onTap: () async {
                          unawaited(ref
                              .read(analyticsFacadeProvider)
                              .trackUserDeleteAccount());

                          context.goNamed(RouteNames.accountDelete.name);
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
                        action: () {
                          launchUrl(Uri.parse('https://ta3afi.app'));
                        },
                      ),
                      verticalSpace(Spacing.points8),
                      SettingsButton(
                        icon: LucideIcons.contact,
                        textKey: 'contact-us-through-this-channels',
                        action: () async {
                          await ref
                              .read(urlLauncherProvider)
                              .launch(Uri.parse('https://t.me/Ta3afiApp'));
                        },
                      ),
                      verticalSpace(Spacing.points8),
                      SettingsButton(
                        icon: LucideIcons.star,
                        textKey: 'rate-app',
                        action: () async {
                          await ref
                              .read(inAppRatingServiceProvider)
                              .requestReview(context);
                        },
                      ),
                      verticalSpace(Spacing.points12),
                    ],
                  ),
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
        return UiAndLanguageSettings();
      },
    );
  }

  void _showResetDataDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ResetDataModalSheet();
      },
    );
  }
}

class ResetDataModalSheet extends ConsumerStatefulWidget {
  const ResetDataModalSheet({Key? key}) : super(key: key);

  @override
  _ResetDataModalSheetState createState() => _ResetDataModalSheetState();
}

class _ResetDataModalSheetState extends ConsumerState<ResetDataModalSheet> {
  bool deleteFollowUps = false;
  bool deleteEmotions = false;
  bool userWantNowAsNewFirstDate = false;
  final startingDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize with current userFirstDate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileNotifierProvider).value;
      if (userProfile != null) {
        setState(() {
          selectedDate = userProfile.userFirstDate;
          startingDateController.text = getDisplayDateTime(
            userProfile.userFirstDate,
            ref.read(localeNotifierProvider)?.languageCode ?? 'en',
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('delete-my-data'),
                  style: TextStyles.h6,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(LucideIcons.xCircle),
                ),
              ],
            ),
            verticalSpace(Spacing.points24),
            Text(
              AppLocalizations.of(context).translate('reset-data-desc'),
              style: TextStyles.caption.copyWith(color: theme.warn[800]),
            ),
            verticalSpace(Spacing.points24),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    startingDateController.text = getDisplayDate(
                      picked,
                      locale?.languageCode ?? 'en',
                    );
                  });
                }
              },
              child: AbsorbPointer(
                child: CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: startingDateController,
                  hint: AppLocalizations.of(context).translate('starting-date'),
                  prefixIcon: LucideIcons.calendar,
                  inputType: TextInputType.datetime,
                ),
              ),
            ),
            verticalSpace(Spacing.points8),
            WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
              boxShadow: Shadows.mainShadows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.bell),
                      horizontalSpace(Spacing.points16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('reset-to-today'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.grey[900],
                            ),
                          ),
                          verticalSpace(Spacing.points4),
                          if (userWantNowAsNewFirstDate)
                            Text(
                              getDisplayDateTime(
                                  DateTime.now(), locale!.languageCode),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: userWantNowAsNewFirstDate,
                    activeColor: theme.primary[600],
                    onChanged: (bool value) {
                      setState(() {
                        userWantNowAsNewFirstDate = value;
                        if (userWantNowAsNewFirstDate) {
                          final selectedStartingDateDisplay = DisplayDateTime(
                              DateTime.now(), locale!.languageCode);
                          startingDateController.text =
                              selectedStartingDateDisplay.displayDateTime;
                          selectedDate = selectedStartingDateDisplay.date;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('daily-follow-ups'),
                        style: TextStyles.body,
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .translate('daily-follow-ups-delete-desc'),
                        style:
                            TextStyles.small.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ),
                horizontalSpace(Spacing.points32),
                Checkbox(
                  value: deleteFollowUps,
                  onChanged: (bool? value) {
                    setState(() {
                      deleteFollowUps = value ?? false;
                    });
                  },
                ),
              ],
            ),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('emotions'),
                        style: TextStyles.body,
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .translate('emotions-delete-desc'),
                        style:
                            TextStyles.small.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ),
                horizontalSpace(Spacing.points32),
                Checkbox(
                  value: deleteEmotions,
                  onChanged: (bool? value) {
                    setState(() {
                      deleteEmotions = value ?? false;
                    });
                  },
                ),
              ],
            ),
            verticalSpace(Spacing.points24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (selectedDate != null) {
                        await userProfileNotifier
                            .updateUserFirstDate(selectedDate!);
                      }
                      if (deleteFollowUps) {
                        await userProfileNotifier.deleteDailyFollowUps();
                      }
                      if (deleteEmotions) {
                        await userProfileNotifier.deleteEmotions();
                      }
                      getSuccessSnackBar(context, 'data-updated-successfully');
                      Navigator.of(context).pop();
                    },
                    child: WidgetsContainer(
                      backgroundColor: theme.backgroundColor,
                      boxShadow: Shadows.mainShadows,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      borderRadius: BorderRadius.circular(10.5),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('confirm'),
                          style:
                              TextStyles.h6.copyWith(color: theme.primary[700]),
                        ),
                      ),
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: WidgetsContainer(
                      backgroundColor: theme.backgroundColor,
                      boxShadow: Shadows.mainShadows,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      borderRadius: BorderRadius.circular(10.5),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('cancel'),
                          style: TextStyles.h6.copyWith(color: theme.grey[900]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    startingDateController.dispose();
    super.dispose();
  }
}

class UiAndLanguageSettings extends ConsumerWidget {
  const UiAndLanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context).translate('ui-settings'),
                      style: TextStyles.h4.copyWith(
                        color: theme.grey[900],
                      ),
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
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  borderRadius: BorderRadius.circular(10.5),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.16),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: Offset(
                        0,
                        1,
                      ),
                    ),
                  ],
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

  _updateThelocale(SegmentedButtonOption value, WidgetRef ref) {
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
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: WidgetsContainer(
          padding: EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(
              color: type == 'error' ? theme.error[600]! : theme.grey[600]!,
              width: 0.5),
          borderRadius: BorderRadius.circular(10.5),
          boxShadow: Shadows.mainShadows,
          child: Row(
            children: [
              Icon(
                icon,
                color: type == 'error' ? theme.error[600]! : theme.grey[900],
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
      ),
    );
  }

  Color _getTextColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'app':
        return theme.primary[600] as Color;
      case 'error':
        return theme.error[600] as Color;
      default:
        return theme.grey[900] as Color;
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
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: WidgetsContainer(
        width: MediaQuery.of(context).size.width - 32,
        padding: EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
        cornerSmoothing: 1,
        boxShadow: Shadows.mainShadows,
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
      ),
    );
  }
}
