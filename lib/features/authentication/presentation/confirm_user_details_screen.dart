import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';

class ConfirmUserDetailsScreen extends ConsumerStatefulWidget {
  const ConfirmUserDetailsScreen({Key? key}) : super(key: key);

  @override
  _ConfirmUserDetailsScreenState createState() =>
      _ConfirmUserDetailsScreenState();
}

class _ConfirmUserDetailsScreenState
    extends ConsumerState<ConfirmUserDetailsScreen> {
  late TextEditingController displayNameController;
  late TextEditingController emailController;
  late TextEditingController dateOfBirthController;
  late DateTime selectedBirthDate;
  late TextEditingController userFirstDateController;
  late DateTime selectedUserFirstDate;
  SegmentedButtonOption? selectedGender;
  SegmentedButtonOption? selectedLocale;

  @override
  void initState() {
    super.initState();
    displayNameController = TextEditingController();
    emailController = TextEditingController();
    dateOfBirthController = TextEditingController();
    userFirstDateController = TextEditingController();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    dateOfBirthController.dispose();
    userFirstDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context, String language) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2010),
    );
    if (picked != null) {
      var date = DisplayDate(picked, language);
      setState(() {
        selectedBirthDate = date.date;
        dateOfBirthController.text = date.displayDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDocumentAsyncValue = ref.watch(userDocumentNotifierProvider);
    final theme = CustomThemeInherited.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final migrateService = ref.watch(migrationServiceProvider);

    return Scaffold(
      appBar: appBar(context, ref, 'confirm-your-details', true),
      body: userDocumentAsyncValue.when(
        data: (userDocument) {
          if (userDocument == null) {
            return Center(child: Text('No user document found.'));
          }

          if (selectedGender == null) {
            displayNameController.text = userDocument.displayName!;
            emailController.text = userDocument.email!;
            var dob = DisplayDate(
                userDocument.dayOfBirth!.toDate(), locale!.languageCode);

            dateOfBirthController.text = dob.displayDate;
            selectedBirthDate = dob.date;

            var displayUserFirstDate = DisplayDateTime(
                userDocument.userFirstDate!.toDate(), locale.languageCode);
            userFirstDateController.text = displayUserFirstDate.displayDateTime;

            selectedUserFirstDate = displayUserFirstDate.date;
            selectedGender = _getGenderActualValue(userDocument.gender!);
            selectedLocale = SegmentedButtonOption(
              value: userDocument.locale!,
              translationKey: userDocument.locale!,
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('confirm-your-details-p'),
                    style: TextStyles.body.copyWith(color: theme.grey[600]),
                  ),
                  verticalSpace(Spacing.points8),
                  CustomTextField(
                    controller: displayNameController,
                    hint: AppLocalizations.of(context).translate('first-name'),
                    prefixIcon: LucideIcons.user,
                    inputType: TextInputType.name,
                  ),
                  verticalSpace(Spacing.points8),
                  CustomTextField(
                    controller: emailController,
                    hint: AppLocalizations.of(context).translate('email'),
                    prefixIcon: LucideIcons.mail,
                    inputType: TextInputType.emailAddress,
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
                    selectedOption: selectedGender!,
                    onChanged: (selection) {
                      setState(() {
                        selectedGender = _getGenderActualValue(selection.value);
                      });
                    },
                  ),
                  verticalSpace(Spacing.points8),
                  CustomSegmentedButton(
                    label: AppLocalizations.of(context)
                        .translate('preferred-language'),
                    options: [
                      SegmentedButtonOption(
                          value: 'english', translationKey: 'english'),
                      SegmentedButtonOption(
                          value: 'arabic', translationKey: 'arabic')
                    ],
                    selectedOption: selectedLocale!,
                    onChanged: (selection) {
                      setState(() {
                        selectedLocale = selection;
                      });
                    },
                  ),
                  verticalSpace(Spacing.points8),
                  Consumer(builder: (context, ref, child) {
                    final locale = ref.watch(localeNotifierProvider);
                    return GestureDetector(
                      onTap: () => _selectDob(context, locale!.languageCode),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: dateOfBirthController,
                          hint: AppLocalizations.of(context)
                              .translate('date-of-birth'),
                          prefixIcon: LucideIcons.calendar,
                          inputType: TextInputType.datetime,
                        ),
                      ),
                    );
                  }),
                  verticalSpace(Spacing.points8),
                  CustomTextField(
                    enabled: false,
                    controller: userFirstDateController,
                    hint:
                        AppLocalizations.of(context).translate('starting-date'),
                    prefixIcon: LucideIcons.calendar,
                    inputType: TextInputType.datetime,
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    AppLocalizations.of(context).translate('starting-date-p'),
                    style: TextStyles.smallBold.copyWith(color: theme.grey),
                  ),
                  verticalSpace(Spacing.points32),
                  GestureDetector(
                    onTap: () async {
                      final uid = userDocument.uid!;
                      final displayName = displayNameController.value.text;
                      final email = emailController.value.text;
                      final dateOfBirth = dateOfBirthController.value.text;
                      final userFirstDate = userFirstDateController.value.text;
                      final selectedGender = this.selectedGender;
                      final selectedLocale = this.selectedLocale;
                      await migrateService.migrateToNewDocuemntStrcture(
                        LegacyUserDocument(
                          uid: uid,
                          displayName: displayName,
                          dayOfBirth: parseDisplayDate(
                              dateOfBirth, locale!.languageCode),
                          userFirstDate: parseDisplayDateTime(
                              userFirstDate, locale.languageCode),
                          email: email,
                          locale: selectedLocale?.value,
                          gender: selectedGender?.value,
                        ),
                      );
                    },
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[600],
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('start-your-journy'),
                          style: TextStyles.caption
                              .copyWith(color: theme.grey[50]),
                        ),
                      ),
                    ),
                  )
                ],
              ),
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

  SegmentedButtonOption _getGenderActualValue(String value) {
    if (value == 'femele') {
      return SegmentedButtonOption(value: 'female', translationKey: "female");
    } else {
      return SegmentedButtonOption(value: value, translationKey: value);
    }
  }
}
