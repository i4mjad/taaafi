import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/new_document_provider.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: appBar(
        context,
        ref,
        'sign-up',
        true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SignUpForm(),
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
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  late DateTime dob = DateTime(1900, 1, 1);
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final startingDateController = TextEditingController();
  late DateTime startingDate;

  SegmentedButtonOption selectedGender =
      SegmentedButtonOption(value: 'male', translationKey: 'male');
  SegmentedButtonOption selectedLanguage =
      SegmentedButtonOption(value: 'english', translationKey: 'english');
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

        var pickedStarting = DisplayDateTime(pickedDateTime, language);
        setState(() {
          nowIsStartingDate = false;
          startingDateController.text = pickedStarting.displayDateTime;
          startingDate = pickedStarting.date;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    final newUserNotifier = ref.watch(newUserDocumentNotifierProvider.notifier);
    final authService = ref.watch(authServiceProvider);
    final theme = CustomThemeInherited.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hint: AppLocalizations.of(context)
                            .translate('first-name'),
                        prefixIcon: LucideIcons.user,
                        inputType: TextInputType.name,
                        width: MediaQuery.of(context).size.width / 2 - (16 + 2),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('cant-be-empty');
                          }
                          return null;
                        },
                      ),
                      GestureDetector(
                        onTap: () => _selectDob(context, locale!.languageCode),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: dobController,
                            hint: AppLocalizations.of(context)
                                .translate('date-of-birth'),
                            prefixIcon: LucideIcons.calendar,
                            inputType: TextInputType.datetime,
                            width: MediaQuery.of(context).size.width / 2 -
                                (16 + 2),
                            validator: (value) {
                              if (dob == null ||
                                  dob == DateTime(1900, 1, 1) ||
                                  value == null ||
                                  value.isEmpty ||
                                  dob.year > 2012) {
                                return AppLocalizations.of(context)
                                    .translate('enter-a-valid-dob');
                              }
                              return null;
                            },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            .translate('cant-be-empty');
                      }

                      if (!AppRegex.isEmailValid(value)) {
                        return AppLocalizations.of(context)
                            .translate('invalid-email');
                      }
                      return null;
                    },
                  ),
                  verticalSpace(Spacing.points8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: passwordController,
                        obscureText: true,
                        hint:
                            AppLocalizations.of(context).translate('password'),
                        prefixIcon: LucideIcons.lock,
                        inputType: TextInputType.visiblePassword,
                        width: MediaQuery.of(context).size.width / 2 - (16 + 2),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('cant-be-empty');
                          } else if (value != null && !value.isEmpty) {
                            if (!AppRegex.hasNumber(value)) {
                              return AppLocalizations.of(context)
                                  .translate('password-must-contain-a-number');
                            }
                            if (!AppRegex.hasMinLength(value)) {
                              return AppLocalizations.of(context).translate(
                                  'password-must-contain-at-least-8-characters');
                            }

                            if (!AppRegex.hasSpecialCharacter(value)) {
                              return AppLocalizations.of(context).translate(
                                  'password-must-contain-at-least-1-special-character');
                            }

                            if (!AppRegex.isPasswordValid(value)) {
                              return AppLocalizations.of(context)
                                  .translate('password-is-not-valid');
                            }
                          }

                          return null;
                        },
                      ),
                      verticalSpace(Spacing.points8),
                      CustomTextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        hint: AppLocalizations.of(context)
                            .translate('repeat-password'),
                        prefixIcon: LucideIcons.lock,
                        inputType: TextInputType.visiblePassword,
                        width: MediaQuery.of(context).size.width / 2 - (16 + 2),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('cant-be-empty');
                          }
                          if (value != passwordController.text) {
                            return AppLocalizations.of(context)
                                .translate('passwords-doesnt-match');
                          }
                          return null;
                        },
                      ),
                    ],
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
                    selectedOption: selectedGender,
                    onChanged: (selection) {
                      setState(() {
                        selectedGender = selection;
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
                    selectedOption: selectedLanguage,
                    onChanged: (selection) {
                      setState(() {
                        selectedLanguage = selection;
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
                    onTap: () =>
                        _selectStartingDate(context, locale!.languageCode),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: startingDateController,
                        hint: AppLocalizations.of(context)
                            .translate('starting-date'),
                        prefixIcon: LucideIcons.calendar,
                        inputType: TextInputType.datetime,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the starting date';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  WidgetsContainer(
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
                                        getDisplayDateTime(DateTime.now(),
                                            locale!.languageCode),
                                        style: TextStyles.footnote.copyWith(
                                          color: theme.grey[400],
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: nowIsStartingDate,
                          activeColor: theme.primary[600],
                          onChanged: (bool value) {
                            setState(
                              () {
                                nowIsStartingDate = !nowIsStartingDate;
                                final selectedDate = DisplayDateTime(
                                    DateTime.now(), locale!.languageCode);
                                startingDateController.text =
                                    selectedDate.displayDateTime;
                                startingDate = selectedDate.date;
                              },
                            );
                          },
                        ),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (_formKey.currentState!.validate() && isTermsAccepted) {
                final name = nameController.value.text;
                final selectedDob = dob;
                final gender = selectedGender.value;
                final locale = selectedLanguage.value;
                final firstDate = startingDate;

                await authService.signUpWithEmail(
                  context,
                  emailController.value.text,
                  passwordController.value.text,
                  name,
                  selectedDob,
                  gender,
                  locale,
                  firstDate,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: WidgetsContainer(
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
            ),
          ),
        ],
      ),
    );
  }
}
