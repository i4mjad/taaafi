import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';

// Helper function to extract line number from stack trace
Map<String, String> getExceptionLocationInfo(StackTrace stackTrace) {
  String stackTraceString = stackTrace.toString();
  List<String> lines = stackTraceString.split('\n');
  Map<String, String> result = {
    'raw_trace': lines.isNotEmpty ? lines[0] : 'Unknown location',
    'file': 'Unknown file',
    'line': 'Unknown line',
    'column': 'Unknown column',
    'method': 'Unknown method'
  };

  // Parse the first relevant line to extract file, line, and column information
  if (lines.length > 1) {
    // Typical format: "#1      _ConfirmUserDetailsScreenState._method (file:///path/to/file.dart:123:45)"
    String traceLine =
        lines[1]; // Use the immediate caller where the exception occurred

    // Extract method name - everything before the file path
    final methodMatch = RegExp(r'#\d+\s+(.+?)\s+\(').firstMatch(traceLine);
    if (methodMatch != null && methodMatch.groupCount >= 1) {
      result['method'] = methodMatch.group(1) ?? 'Unknown method';
    }

    // Extract file path, line, and column
    final locationMatch =
        RegExp(r'\((.+?):(\d+):(\d+)\)').firstMatch(traceLine);
    if (locationMatch != null && locationMatch.groupCount >= 3) {
      result['file'] = locationMatch.group(1) ?? 'Unknown file';
      result['line'] = locationMatch.group(2) ?? 'Unknown line';
      result['column'] = locationMatch.group(3) ?? 'Unknown column';
    }

    result['raw_trace'] = traceLine;
  }

  return result;
}

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
  DateTime? selectedBirthDate;
  late TextEditingController userFirstDateController;
  DateTime? selectedUserFirstDate;
  SegmentedButtonOption? selectedGender;
  SegmentedButtonOption? selectedLocale;
  bool _isProcessing = false;

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
    final lastDate = DateTime(2010, 12, 31);
    final firstDate = DateTime(1950);
    DateTime initialDate = DateTime(2010);

    if (selectedBirthDate != null &&
        selectedBirthDate!.isBefore(lastDate) &&
        !selectedBirthDate!.isBefore(firstDate)) {
      initialDate = selectedBirthDate!;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      var date = DisplayDate(picked, language);
      setState(() {
        selectedBirthDate = picked;
        dateOfBirthController.text = date.displayDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDocumentAsyncValue = ref.watch(userDocumentsNotifierProvider);
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final migrateService = ref.watch(migrationServiceProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'review-your-details', true, true),
      body: userDocumentAsyncValue.when(
        data: (userDocument) {
          if (userDocument == null) {
            return Center(child: Text('No user document found.'));
          }

          // Populate fields if not already set
          if (selectedGender == null) {
            displayNameController.text = userDocument.displayName ?? "";
            emailController.text = userDocument.email ?? "";

            if (userDocument.dayOfBirth != null) {
              var dob = DisplayDate(
                userDocument.dayOfBirth!.toDate(),
                locale?.languageCode ?? 'en',
              );
              dateOfBirthController.text = dob.displayDate;
              selectedBirthDate = dob.date;
            }

            final userFirstDate =
                userDocument.userFirstDate?.toDate() ?? DateTime.now();
            var displayUserFirstDate =
                DisplayDateTime(userFirstDate, locale?.languageCode ?? 'en');
            userFirstDateController.text = displayUserFirstDate.displayDateTime;
            selectedUserFirstDate = displayUserFirstDate.date;

            selectedGender = userDocument.gender != null
                ? _getGenderActualValue(userDocument.gender!)
                : SegmentedButtonOption(value: 'male', translationKey: 'male');

            selectedLocale = SegmentedButtonOption(
              value: userDocument.locale ?? 'english',
              translationKey: userDocument.locale ?? 'english',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            .translate('cant-be-empty');
                      }
                      return null;
                    },
                  ),
                  verticalSpace(Spacing.points8),
                  CustomTextField(
                    controller: emailController,
                    hint: AppLocalizations.of(context).translate('email'),
                    prefixIcon: LucideIcons.mail,
                    enabled: userDocument.email == null,
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
                  CustomSegmentedButton(
                    label: AppLocalizations.of(context).translate('gender'),
                    options: [
                      SegmentedButtonOption(
                          value: 'male', translationKey: 'male'),
                      SegmentedButtonOption(
                          value: 'female', translationKey: 'female')
                    ],
                    selectedOption: selectedGender ??
                        SegmentedButtonOption(
                            value: 'male', translationKey: 'male'),
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
                    selectedOption: selectedLocale ??
                        SegmentedButtonOption(
                            value: 'english', translationKey: 'english'),
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
                      onTap: () {
                        _selectDob(context, locale?.languageCode ?? 'en');
                      },
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: dateOfBirthController,
                          hint: AppLocalizations.of(context)
                              .translate('date-of-birth'),
                          prefixIcon: LucideIcons.calendar,
                          inputType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('cant-be-empty');
                            }
                            return null;
                          },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            .translate('cant-be-empty');
                      }
                      return null;
                    },
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    AppLocalizations.of(context).translate('starting-date-p'),
                    style: TextStyles.smallBold.copyWith(color: theme.grey),
                  ),
                  verticalSpace(Spacing.points32),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                setState(() => _isProcessing = true);

                                // Validate date of birth
                                if (selectedBirthDate != null &&
                                    selectedBirthDate!
                                        .isAfter(DateTime(2010, 12, 31))) {
                                  getErrorSnackBar(context, "dob-too-young");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                // Validate display name
                                if (displayNameController.text.trim().isEmpty) {
                                  getErrorSnackBar(
                                      context, "name-should-not-be-empty");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                // Validate email
                                if (emailController.text.trim().isEmpty) {
                                  getErrorSnackBar(
                                      context, "email-should-not-be-empty");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                // Validate gender and locale
                                if (selectedGender == null ||
                                    selectedLocale == null) {
                                  getErrorSnackBar(
                                      context, "please-add-all-required-data");
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                try {
                                  // Create new user document
                                  final newUserDoc = UserDocument(
                                    uid: userDocument.uid ??
                                        '', // Handle null UID
                                    displayName:
                                        displayNameController.text.trim(),
                                    dayOfBirth: selectedBirthDate != null
                                        ? Timestamp.fromDate(selectedBirthDate!)
                                        : null,
                                    userFirstDate: userDocument.userFirstDate,
                                    email: emailController.text.trim(),
                                    role: "user",
                                    locale: selectedLocale?.value,
                                    gender: selectedGender?.value,
                                    userRelapses: userDocument.userRelapses,
                                    userWatchingWithoutMasturbating:
                                        userDocument
                                            .userWatchingWithoutMasturbating,
                                    userMasturbatingWithoutWatching:
                                        userDocument
                                            .userMasturbatingWithoutWatching,
                                  );

                                  await migrateService
                                      .migrateToNewDocuemntStrcture(newUserDoc);

                                  unawaited(ref
                                      .read(analyticsFacadeProvider)
                                      .trackOnboardingFinish());

                                  // Force a refresh of the user document provider
                                  await ref.refresh(
                                      userDocumentsNotifierProvider.future);

                                  if (!mounted) return;
                                  context.goNamed(RouteNames.home.name);
                                } catch (e, stackTrace) {
                                  // Log error with context and specific error details
                                  final locationInfo =
                                      getExceptionLocationInfo(stackTrace);
                                  ref.read(errorLoggerProvider).logException(
                                    e,
                                    stackTrace, // Use the actual caught stackTrace
                                    context: {
                                      'error_type': e.runtimeType.toString(),
                                      'error_message': e.toString(),
                                      'source_file': locationInfo['file'],
                                      'source_line': locationInfo['line'],
                                      'source_column': locationInfo['column'],
                                      'source_method': locationInfo['method'],
                                      'migration_context': {
                                        'user_id': userDocument.uid,
                                        'display_name':
                                            displayNameController.text,
                                        'email': emailController.text,
                                        'selected_birth_date':
                                            selectedBirthDate?.toString(),
                                        'selected_locale':
                                            selectedLocale?.value,
                                        'selected_gender':
                                            selectedGender?.value,
                                      }
                                    },
                                  );

                                  String errorKey = "something-went-wrong";

                                  if (e is FirebaseException) {
                                    switch (e.code) {
                                      case 'permission-denied':
                                        errorKey = "permission-denied";
                                        break;
                                      case 'not-found':
                                        errorKey = "user-not-found";
                                        break;
                                    }
                                  } else if (e is TimeoutException) {
                                    errorKey = "connection-timeout";
                                  }

                                  if (mounted) {
                                    getErrorSnackBar(context, errorKey);
                                    setState(() => _isProcessing = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isProcessing
                              ? theme.grey[400]
                              : theme.primary[600],
                          minimumSize: const Size.fromHeight(48),
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 10.5,
                              cornerSmoothing: 1,
                            ),
                          ),
                        ),
                        child: _isProcessing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                        .translate('processing'),
                                    style: TextStyles.caption
                                        .copyWith(color: theme.grey[50]),
                                  ),
                                ],
                              )
                            : Text(
                                AppLocalizations.of(context)
                                    .translate('confirm-user-details'),
                                style: TextStyles.caption
                                    .copyWith(color: theme.grey[50]),
                              ),
                      ),
                    ],
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

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  String? validateUserDocument(UserDocument doc) {
    if (doc.uid?.isEmpty ?? true) {
      return 'Invalid UID';
    }

    if (displayNameController.text.trim().isEmpty) {
      return 'Display name is required';
    }

    if (!AppRegex.isEmailValid(emailController.text.trim())) {
      return 'Invalid email format';
    }

    if (selectedGender == null || selectedLocale == null) {
      return 'Gender and locale are required';
    }

    if (selectedBirthDate != null) {
      if (selectedBirthDate!.isAfter(DateTime(2010, 12, 31))) {
        return 'Invalid birth date';
      }
    }

    return null;
  }
}
