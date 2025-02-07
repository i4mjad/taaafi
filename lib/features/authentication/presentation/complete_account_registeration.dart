// ignore_for_file: unused_result

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';

class CompleteAccountRegisterationScreen extends ConsumerStatefulWidget {
  const CompleteAccountRegisterationScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteAccountRegisterationScreenState();
}

class _CompleteAccountRegisterationScreenState
    extends ConsumerState<CompleteAccountRegisterationScreen> {
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
  bool _isProcessing = false;

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
    // Calculate the valid date range
    final lastDate = DateTime(2010, 12, 31); // Must be before 2011
    final firstDate = DateTime(1960);

    DateTime initialDate = DateTime(2010);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    final authService = ref.watch(authServiceProvider);
    final theme = AppTheme.of(context);
    final userNotifer = ref.watch(userNotifierProvider);

    return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar:
            appBar(context, ref, 'complete-account-registeration', false, true),
        body: userNotifer.when(
          data: (user) {
            if (user == null) {
              return Center(
                  child: Text("User not exist, please re-download the app"));
            }
            if (nameController.text.isEmpty) {
              nameController.text = user.displayName ?? "";
            }
            if (emailController.text.isEmpty) {
              emailController.text = user.email ?? "";
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    controller: nameController,
                                    hint: AppLocalizations.of(context)
                                        .translate('first-name'),
                                    prefixIcon: LucideIcons.user,
                                    inputType: TextInputType.name,
                                    enabled: user.displayName == null,
                                    width:
                                        MediaQuery.of(context).size.width / 2 -
                                            (16 + 2),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)
                                            .translate('cant-be-empty');
                                      }
                                      return null;
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () => _selectDob(
                                        context, locale!.languageCode),
                                    child: AbsorbPointer(
                                      child: CustomTextField(
                                        controller: dobController,
                                        hint: AppLocalizations.of(context)
                                            .translate('date-of-birth'),
                                        prefixIcon: LucideIcons.calendar,
                                        inputType: TextInputType.datetime,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                    2 -
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
                                hint: AppLocalizations.of(context)
                                    .translate('email'),
                                enabled: user.email == null,
                                prefixIcon: LucideIcons.mail,
                                inputType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)
                                        .translate('cant-be-empty');
                                  } else if (!AppRegex.isEmailValid(value)) {
                                    return AppLocalizations.of(context)
                                        .translate('enter-a-valid-email');
                                  }
                                  return null;
                                },
                              ),
                              verticalSpace(Spacing.points8),
                              // CustomSegmentedButton(
                              //   label: AppLocalizations.of(context)
                              //       .translate('gender'),
                              //   options: [
                              //     SegmentedButtonOption(
                              //         value: 'male', translationKey: 'male'),
                              //     SegmentedButtonOption(
                              //         value: 'female', translationKey: 'female')
                              //   ],
                              //   selectedOption: selectedGender,
                              //   onChanged: (selection) {
                              //     setState(() {
                              //       selectedGender = selection;
                              //     });
                              //   },
                              // ),
                              // verticalSpace(Spacing.points8),
                              CustomSegmentedButton(
                                label: AppLocalizations.of(context)
                                    .translate('preferred-language'),
                                options: [
                                  SegmentedButtonOption(
                                      value: 'arabic',
                                      translationKey: 'arabic'),
                                  SegmentedButtonOption(
                                      value: 'english',
                                      translationKey: 'english')
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
                                style: TextStyles.h6
                                    .copyWith(color: theme.grey[900]),
                              ),
                              verticalSpace(Spacing.points8),
                              Text(
                                'متى تريد البدء في متابعة تعافيك؟ التاريخ الذي ستقوم باختياره، سنقوم ببدء العد منه',
                                style: TextStyles.footnote
                                    .copyWith(color: theme.grey[600]),
                              ),
                              verticalSpace(Spacing.points8),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _selectStartingDate(
                                      context, locale!.languageCode);
                                },
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.bell),
                                        horizontalSpace(Spacing.points16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "البدء من الآن",
                                              style:
                                                  TextStyles.footnote.copyWith(
                                                color: theme.grey[900],
                                              ),
                                            ),
                                            verticalSpace(Spacing.points4),
                                            if (nowIsStartingDate)
                                              Text(
                                                getDisplayDateTime(
                                                    DateTime.now(),
                                                    locale!.languageCode),
                                                style: TextStyles.footnote
                                                    .copyWith(
                                                  color: theme.grey[400],
                                                ),
                                              )
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
                                            nowIsStartingDate =
                                                !nowIsStartingDate;
                                            final selectedDate =
                                                DisplayDateTime(DateTime.now(),
                                                    locale!.languageCode);
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
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref.read(urlLauncherProvider).launch(
                                            Uri.parse(
                                                'https://www.ta3afi.app/ar/terms'),
                                          );
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate('i-accept-terms-of-use'),
                                      style:
                                          TextStyles.footnoteSelected.copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isProcessing
                            ? null
                            : () async {
                                setState(() => _isProcessing = true);

                                if (isTermsAccepted == false) {
                                  getErrorSnackBar(
                                      context, "terms-should-be-accepted");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                if (nameController.text.trim().isEmpty) {
                                  getErrorSnackBar(
                                      context, "name-should-not-be-empty");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                if (emailController.text.trim().isEmpty) {
                                  getErrorSnackBar(
                                      context, "email-should-not-be-empty");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                if (_formKey.currentState!.validate() &&
                                    isTermsAccepted) {
                                  try {
                                    final name = nameController.value.text;
                                    final selectedDob = dob;
                                    final gender =
                                        ""; //! TODO: this to be added later
                                    final locale = selectedLanguage.value;
                                    final firstDate = startingDate;

                                    // Track analytics before the async operations
                                    unawaited(ref
                                        .read(analyticsFacadeProvider)
                                        .trackOnboardingFinish());

                                    // Complete the registration
                                    await authService
                                        .completeAccountRegiseration(
                                            context,
                                            name,
                                            dob,
                                            gender,
                                            locale,
                                            firstDate);

                                    // Wait for the user document to be refreshed
                                    await ref.refresh(
                                        userDocumentsNotifierProvider.future);

                                    if (!mounted) return;

                                    // Navigate after ensuring the state is updated
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      context.goNamed(RouteNames.home.name);
                                    });
                                  } catch (e, stackTrace) {
                                    ref
                                        .read(errorLoggerProvider)
                                        .logException(e, stackTrace);
                                    if (mounted) {
                                      getErrorSnackBar(
                                          context, "something-went-wrong");
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: WidgetsContainer(
                            backgroundColor: _isProcessing
                                ? theme.grey[400]
                                : theme.primary[600],
                            width:
                                MediaQuery.of(context).size.width - (16 + 16),
                            padding: EdgeInsets.only(top: 12, bottom: 12),
                            borderRadius: BorderRadius.circular(10.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isProcessing) ...[
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.grey[50]!),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('processing-new-account'),
                                    style: TextStyles.footnoteSelected
                                        .copyWith(color: theme.grey[50]),
                                  ),
                                ] else
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('sign-up'),
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
        ));
  }
}
