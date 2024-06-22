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

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'sign-up',
        true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SignUpForm(),
                    ],
                  ),
                ),
              ),
            ),
            WidgetsContainer(
              backgroundColor: theme.primary[600],
              width: MediaQuery.of(context).size.width - (16 + 16),
              padding: EdgeInsets.only(top: 12, bottom: 12),
              borderRadius: BorderRadius.circular(10.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('sign-up'),
                    style: TextStyles.footnoteSelected
                        .copyWith(color: theme.grey[50]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpForm extends ConsumerStatefulWidget {
  SignUpForm({
    super.key,
  });

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final startingDateController = TextEditingController();
  String selectedGender = 'Male';
  String selectedLanguage = 'English';
  bool nowIsStartingDate = false;
  bool isTermsAccepted = false;

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context, String language) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = getDisplayDate(picked, language);
      });
    }
  }

  Future<void> _selectStartingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          nowIsStartingDate = false;
          startingDateController.text =
              getDisplayDateTime(pickedDateTime, language);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = CustomThemeInherited.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextField(
              controller: nameController,
              hint: AppLocalizations.of(context).translate('first-name'),
              prefixIcon: LucideIcons.user,
              inputType: TextInputType.name,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
            GestureDetector(
              onTap: () => _selectDob(context, locale!.languageCode),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: dobController,
                  hint: AppLocalizations.of(context).translate('date-of-birth'),
                  prefixIcon: LucideIcons.calendar,
                  inputType: TextInputType.datetime,
                  width: MediaQuery.of(context).size.width / 2 - (16 + 2),
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
        ),
        verticalSpace(Spacing.points8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextField(
              controller: passwordController,
              obscureText: true,
              hint: AppLocalizations.of(context).translate('password'),
              prefixIcon: LucideIcons.lock,
              inputType: TextInputType.visiblePassword,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
            verticalSpace(Spacing.points8),
            CustomTextField(
              controller: confirmPasswordController,
              obscureText: true,
              hint: AppLocalizations.of(context).translate('repeat-password'),
              prefixIcon: LucideIcons.lock,
              inputType: TextInputType.visiblePassword,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('gender'),
          options: [
            AppLocalizations.of(context).translate('male'),
            AppLocalizations.of(context).translate('female')
          ],
          selectedOption: selectedGender,
          onChanged: (value) {
            setState(() {
              selectedGender = value!;
            });
          },
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('preferred-language'),
          options: [
            'العربية',
            'English',
          ],
          selectedOption: selectedLanguage,
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
          },
        ),
        verticalSpace(Spacing.points16),
        Text(
          'متابعة التعافي',
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points8),
        Text(
          'متى تريد البدء في متابعة تعافيك؟ التاريخ الذي ستقوم باختياره، سنقوم ببدء العد منه',
          style: TextStyles.footnote.copyWith(color: theme.grey[600]),
        ),
        verticalSpace(Spacing.points8),
        GestureDetector(
          onTap: () => _selectStartingDate(context, locale!.languageCode),
          child: AbsorbPointer(
            child: CustomTextField(
              controller: startingDateController,

              prefixIcon: LucideIcons.calendar,
              inputType: TextInputType.datetime,
              // width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
          ),
        ),
        verticalSpace(Spacing.points8),
        WidgetsContainer(
          // padding: EdgeInsets.all(8),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                        "البدء من الآن",
                        style: TextStyles.footnote.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                      verticalSpace(Spacing.points4),
                      Builder(
                        builder: (BuildContext context) {
                          if (nowIsStartingDate) {
                            return Text(
                              getDisplayDateTime(
                                  DateTime.now(), locale!.languageCode),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[400],
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ],
                  )
                ],
              ),
              Switch(
                // This bool value toggles the switch.
                value: nowIsStartingDate,
                activeColor: theme.primary[600],
                onChanged: (bool value) {
                  // This is called when the user toggles the switch.
                  setState(() {
                    //TODO: set the value of the starting date as of now
                    nowIsStartingDate = !nowIsStartingDate;
                    startingDateController.text = getDisplayDateTime(
                        DateTime.now(), locale!.languageCode);
                  });
                },
              )
            ],
          ),
        ),
        verticalSpace(Spacing.points8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: isTermsAccepted,
              onChanged: (value) {
                setState(() {
                  isTermsAccepted = !isTermsAccepted;
                });
              },
            ),
            horizontalSpace(Spacing.points4),
            Text(
              'أوافق على شروط الاستخدام',
              style: TextStyles.footnoteSelected,
            )
          ],
        )
      ],
    );
  }
}
