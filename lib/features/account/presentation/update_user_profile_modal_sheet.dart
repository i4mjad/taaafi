import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
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
  late SegmentedButtonOption gender;
  late SegmentedButtonOption locale;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    dobController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: appBar(context, ref, 'my-profile', false, false),
      backgroundColor: theme.backgroundColor,
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (nameController.text.isEmpty) {
            nameController.text = userProfile.displayName;
            emailController.text = userProfile.email;
            gender = SegmentedButtonOption(
              value: userProfile.gender,
              translationKey: userProfile.gender,
            );
            locale = SegmentedButtonOption(
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
                CustomSegmentedButton(
                  label: AppLocalizations.of(context).translate('gender'),
                  options: [
                    SegmentedButtonOption(
                        value: 'male', translationKey: 'male'),
                    SegmentedButtonOption(
                        value: 'female', translationKey: 'female')
                  ],
                  selectedOption: gender,
                  onChanged: (selection) {
                    setState(() {
                      gender = selection;
                    });
                  },
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
                  selectedOption: locale,
                  onChanged: (selection) {
                    setState(() {
                      locale = selection;
                    });
                  },
                ),
                Spacer(),
                GestureDetector(
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
                verticalSpace(Spacing.points36)
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(),
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
          actionsAlignment: MainAxisAlignment.start,
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
              Text(
                '${AppLocalizations.of(context).translate('email')}: ${emailController.text}',
                style: TextStyles.small,
              ),
              Text(
                '${AppLocalizations.of(context).translate('gender')}: ${AppLocalizations.of(context).translate(gender.translationKey)}',
                style: TextStyles.small,
              ),
              Text(
                '${AppLocalizations.of(context).translate('preferred-language')}: ${AppLocalizations.of(context).translate(locale.translationKey)}',
                style: TextStyles.small,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // TODO: add a function here to handle the profile update
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Close the dialog
                // TODO: show a snackbar
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
}
