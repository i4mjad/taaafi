import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';

class UpdateUserProfileModalSheet extends ConsumerStatefulWidget {
  UpdateUserProfileModalSheet({Key? key}) : super(key: key);

  @override
  _UpdateUserProfileModalSheetState createState() =>
      _UpdateUserProfileModalSheetState();
}

class _UpdateUserProfileModalSheetState
    extends ConsumerState<UpdateUserProfileModalSheet> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController userFirstDateController;
  late TextEditingController roleController;
  late SegmentedButtonOption selectedGender;
  late SegmentedButtonOption selectedLocale;
  late DateTime dob;
  late String role;
  late DateTime userFirstDate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    dobController = TextEditingController();
    userFirstDateController = TextEditingController();
    roleController = TextEditingController();
    dob = DateTime(1900, 1, 1);
    userFirstDate = DateTime.now();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    userFirstDateController.dispose();
    roleController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context, String language) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2012),
      firstDate: DateTime(1950),
      lastDate: DateTime(2012),
    );

    if (picked != null) {
      var pickedDob = DisplayDate(picked, language);
      setState(() {
        dobController.text = pickedDob.displayDate;
        dob = pickedDob.date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return Scaffold(
      appBar: appBar(context, ref, 'my-profile', false, false),
      backgroundColor: theme.backgroundColor,
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return Center(
              child: Spinner(),
            );
          }

          if (nameController.text.isEmpty) {
            nameController.text = userProfile.displayName;
            emailController.text = userProfile.email;
            dobController.text = getDisplayDateTime(
                userProfile.dayOfBirth, locale!.languageCode);
            dob = userProfile.dayOfBirth;
            userFirstDateController.text = getDisplayDateTime(
                userProfile.userFirstDate, locale.languageCode);
            userFirstDate = userProfile.userFirstDate;
            roleController.text =
                AppLocalizations.of(context).translate(userProfile.role);
            role = userProfile.role;
            selectedGender = SegmentedButtonOption(
              value: userProfile.gender,
              translationKey: userProfile.gender,
            );
            selectedLocale = SegmentedButtonOption(
              value: userProfile.locale,
              translationKey: userProfile.locale,
            );
          }

          return Container(
            padding: EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: nameController,
                  prefixIcon: LucideIcons.user,
                  inputType: TextInputType.name,
                  hint: AppLocalizations.of(context).translate('first-name'),
                ),
                verticalSpace(Spacing.points8),
                CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: emailController,
                  prefixIcon: LucideIcons.mail,
                  inputType: TextInputType.emailAddress,
                  hint: AppLocalizations.of(context).translate('email'),
                  enabled: false,
                ),
                verticalSpace(Spacing.points8),
                GestureDetector(
                  onTap: () => _selectDob(context, locale!.languageCode),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      validator: (value) {
                        return null;
                      },
                      controller: dobController,
                      prefixIcon: LucideIcons.calendar,
                      inputType: TextInputType.datetime,
                      hint: AppLocalizations.of(context)
                          .translate('date-of-birth'),
                    ),
                  ),
                ),
                verticalSpace(Spacing.points8),
                CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: userFirstDateController,
                  prefixIcon: LucideIcons.calendar,
                  inputType: TextInputType.datetime,
                  hint: AppLocalizations.of(context).translate('starting-date'),
                  enabled: false,
                ),
                verticalSpace(Spacing.points8),
                CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: roleController,
                  prefixIcon: LucideIcons.userCheck,
                  inputType: TextInputType.text,
                  hint: AppLocalizations.of(context).translate('role'),
                  enabled: false,
                ),
                verticalSpace(Spacing.points8),
                CustomTextField(
                  validator: (value) {
                    return null;
                  },
                  controller: TextEditingController(
                    text: AppLocalizations.of(context).translate(selectedGender.translationKey),
                  ),
                  prefixIcon: LucideIcons.users,
                  inputType: TextInputType.text,
                  hint: AppLocalizations.of(context).translate('gender'),
                  enabled: false,
                ),
                verticalSpace(Spacing.points8),
                CustomSegmentedButton(
                  label: AppLocalizations.of(context)
                      .translate('preferred-language'),
                  options: [
                    SegmentedButtonOption(
                        value: 'arabic', translationKey: 'arabic'),
                    SegmentedButtonOption(
                        value: 'english', translationKey: 'english')
                  ],
                  selectedOption: selectedLocale,
                  onChanged: (selection) {
                    setState(() {
                      selectedLocale = selection;
                    });
                  },
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _showConfirmationDialog(context);
                        },
                        child: WidgetsContainer(
                          backgroundColor: theme.primary[600],
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('update-profile'),
                                style: TextStyles.caption
                                    .copyWith(color: theme.grey[50]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: WidgetsContainer(
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: theme.backgroundColor,
                          borderSide:
                              BorderSide(color: theme.grey[600]!, width: 0.25),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(50, 50, 93, 0.25),
                              blurRadius: 5,
                              spreadRadius: -1,
                              offset: Offset(
                                0,
                                2,
                              ),
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.3),
                              blurRadius: 3,
                              spreadRadius: -1,
                              offset: Offset(
                                0,
                                1,
                              ),
                            ),
                          ],
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context).translate('cancel'),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[900],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points36)
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        loading: () => Center(
          child: Spinner(),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = AppTheme.of(context);
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.end,
          backgroundColor: theme.backgroundColor,
          title: Text(
            AppLocalizations.of(context).translate('confirm-your-details-p'),
            style: TextStyles.h6,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context).translate('first-name')}: ${nameController.text}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('email')}: ${emailController.text}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('date-of-birth')}: ${dobController.text}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('starting-date')}: ${userFirstDateController.text}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('role')}: ${roleController.text}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('gender')}: ${AppLocalizations.of(context).translate(selectedGender.translationKey)}',
                style: TextStyles.small,
              ),
              verticalSpace(Spacing.points8),
              Text(
                '${AppLocalizations.of(context).translate('preferred-language')}: ${AppLocalizations.of(context).translate(selectedLocale.translationKey)}',
                style: TextStyles.small,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _updateUserProfile();
                unawaited(
                    ref.read(analyticsFacadeProvider).trackUserUpdateProfile());
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Close the dialog
                getSnackBar(context, "profile-updated");
              },
              child: Text(
                AppLocalizations.of(context).translate('confirm'),
                style: TextStyles.h6.copyWith(
                  color: theme.success[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                AppLocalizations.of(context).translate('cancel'),
                style: TextStyles.h6.copyWith(
                  color: theme.error[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateUserProfile() async {
    await ref.read(userProfileNotifierProvider.notifier).updateUserProfile(
          displayName: nameController.text,
          email: emailController.text,
          gender: selectedGender.value,
          locale: selectedLocale.value,
          dayOfBirth: dob,
          userFirstDate: userFirstDate,
          role: role,
        );
  }
}
