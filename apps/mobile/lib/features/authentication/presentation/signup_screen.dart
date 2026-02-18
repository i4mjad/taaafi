import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_date_picker.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/referral/presentation/widgets/referral_code_input_widget.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new stepper-based signup flow for better UX
    return const SignUpStepperScreen();
  }
}

class SignUpStepperScreen extends ConsumerStatefulWidget {
  const SignUpStepperScreen({super.key});

  @override
  ConsumerState<SignUpStepperScreen> createState() =>
      _SignUpStepperScreenState();
}

class _SignUpStepperScreenState extends ConsumerState<SignUpStepperScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isProcessing = false;

  // Step 0: Account Creation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 1: Personal Information
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;

  // Step 2: Preferences
  SegmentedButtonOption _selectedGender =
      SegmentedButtonOption(value: 'male', translationKey: 'male');
  SegmentedButtonOption _selectedLanguage =
      SegmentedButtonOption(value: 'english', translationKey: 'english');

  // Step 3: Recovery Setup
  DateTime? _startingDate;
  bool _startFromNow = false;

  // Step 4: Terms Acceptance
  bool _termsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final locale = ref.read(localeNotifierProvider);
    return DisplayDate(date, locale?.languageCode ?? 'en').displayDate;
  }

  String _formatDateTime(DateTime date) {
    final locale = ref.read(localeNotifierProvider);
    return DisplayDateTime(date, locale?.languageCode ?? 'en').displayDateTime;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Account Creation
        if (_emailController.text.trim().isEmpty ||
            !AppRegex.isEmailValid(_emailController.text.trim())) {
          getErrorSnackBar(context, 'valid-email-required');
          return false;
        }
        if (_passwordController.text.trim().isEmpty ||
            !AppRegex.isPasswordValid(_passwordController.text.trim())) {
          getErrorSnackBar(context, 'valid-password-required');
          return false;
        }
        if (_confirmPasswordController.text != _passwordController.text) {
          getErrorSnackBar(context, 'passwords-doesnt-match');
          return false;
        }
        return true;

      case 1: // Personal Information
        if (_nameController.text.trim().isEmpty) {
          getErrorSnackBar(context, 'name-required');
          return false;
        }
        if (_dateOfBirth == null ||
            _dateOfBirth!.isAfter(DateTime(2015, 12, 31))) {
          getErrorSnackBar(context, 'valid-birth-date-required');
          return false;
        }
        return true;

      case 2: // Preferences
        return true; // Always valid as we have defaults

      case 3: // Recovery Setup
        if (_startingDate == null && !_startFromNow) {
          getErrorSnackBar(context, 'starting-date-required');
          return false;
        }
        return true;

      case 4: // Terms Acceptance (no email verification needed yet)
        if (!_termsAccepted) {
          getErrorSnackBar(context, 'terms-acceptance-required');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 4) {
      if (mounted) setState(() => _currentStep++);
    } else {
      // Final step - create account, complete registration and show referral code input
      await _createAccountAndCompleteRegistration();
      if (mounted) {
        // Small delay to ensure context is ready for bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          // Show referral code input as optional bottom sheet
          _showReferralCodeSheet();
        }
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0 && mounted) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _createAccountAndCompleteRegistration() async {
    if (mounted) setState(() => _isProcessing = true);

    try {
      final authService = ref.read(authServiceProvider);
      final finalStartingDate = _startFromNow ? DateTime.now() : _startingDate!;

      // Use the signUpWithEmail method which creates account AND user document
      await authService.signUpWithEmail(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _dateOfBirth!,
        _selectedGender.value,
        _selectedLanguage.value,
        finalStartingDate,
      );

      unawaited(ref.read(analyticsFacadeProvider).trackUserSignup());
      await ref.refresh(userDocumentsNotifierProvider.future);

      if (mounted) {
        getSuccessSnackBar(context, 'account-created-successfully');
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      if (mounted) getErrorSnackBar(context, 'registration-failed');
      rethrow;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showReferralCodeSheet() {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points24),

                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.primary[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 40,
                        color: theme.primary[600],
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points24),

                  // Title
                  Text(
                    AppLocalizations.of(context)
                        .translate('referral.input.title'),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  verticalSpace(Spacing.points12),

                  // Subtitle
                  Text(
                    AppLocalizations.of(context)
                        .translate('referral.input.subtitle'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  verticalSpace(Spacing.points32),

                  // Referral code input widget
                  ReferralCodeInputWidget(
                    onSuccess: () {
                      Navigator.of(context).pop();
                      context.goNamed(RouteNames.ta3afiPlus.name);
                    },
                    onSkip: () {
                      Navigator.of(context).pop();
                      context.goNamed(RouteNames.ta3afiPlus.name);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'sign-up', _currentStep > 0, true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Horizontal Step Indicator
              _buildHorizontalStepIndicator(theme),
              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(),
                ),
              ),
              // Controls
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalStepIndicator(dynamic theme) {
    const int totalSteps = 5;
    final stepLabels = [
      'account',
      'personal-info',
      'preferences',
      'recovery',
      'complete',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final isAccessible = index <= _currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: isAccessible
                  ? () {
                      if (mounted) setState(() => _currentStep = index);
                    }
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? theme.primary[600]
                                : theme.grey[300],
                          ),
                        ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? theme.primary[600]
                              : isActive
                                  ? theme.primary[100]
                                  : theme.grey[100],
                          border: Border.all(
                            color: isCompleted || isActive
                                ? theme.primary[600]!
                                : theme.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  LucideIcons.check,
                                  color: theme.grey[50],
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyles.footnote.copyWith(
                                    color: isActive
                                        ? theme.primary[600]
                                        : theme.grey[500],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      if (index < totalSteps - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? theme.primary[600]
                                : theme.grey[300],
                          ),
                        ),
                    ],
                  ),
                  verticalSpace(Spacing.points8),
                  // Step label
                  Text(
                    AppLocalizations.of(context).translate(stepLabels[index]),
                    style: TextStyles.small.copyWith(
                      color: isActive
                          ? theme.primary[600]
                          : isCompleted
                              ? theme.grey[700]
                              : theme.grey[400],
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAccountCreationContent();
      case 1:
        return _buildPersonalInfoContent();
      case 2:
        return _buildPreferencesContent();
      case 3:
        return _buildRecoverySetupContent();
      case 4:
        return _buildEmailVerificationContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAccountCreationContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('create-account'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context)
              .translate('account-creation-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points24),
        CustomTextField(
          controller: _emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).translate('field-required');
            }
            if (!AppRegex.isEmailValid(value.trim())) {
              return AppLocalizations.of(context).translate('invalid-email');
            }
            return null;
          },
        ),
        verticalSpace(Spacing.points16),
        CustomTextField(
          controller: _passwordController,
          hint: AppLocalizations.of(context).translate('password'),
          prefixIcon: LucideIcons.lock,
          inputType: TextInputType.visiblePassword,
          obscureText: true,
          showObscureToggle: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).translate('field-required');
            }
            if (!AppRegex.hasMinLength(value)) {
              return AppLocalizations.of(context)
                  .translate('password-must-contain-at-least-8-characters');
            }
            if (!AppRegex.hasNumber(value)) {
              return AppLocalizations.of(context)
                  .translate('password-must-contain-a-number');
            }
            if (!AppRegex.hasSpecialCharacter(value)) {
              return AppLocalizations.of(context).translate(
                  'password-must-contain-at-least-1-special-character');
            }
            return null;
          },
        ),
        verticalSpace(Spacing.points16),
        CustomTextField(
          controller: _confirmPasswordController,
          hint: AppLocalizations.of(context).translate('repeat-password'),
          prefixIcon: LucideIcons.lock,
          inputType: TextInputType.visiblePassword,
          obscureText: true,
          showObscureToggle: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).translate('field-required');
            }
            if (value != _passwordController.text) {
              return AppLocalizations.of(context)
                  .translate('passwords-doesnt-match');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('personal-information'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('personal-info-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points24),
        CustomTextField(
          controller: _nameController,
          hint: AppLocalizations.of(context).translate('first-name'),
          prefixIcon: LucideIcons.user,
          inputType: TextInputType.name,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).translate('field-required');
            }
            return null;
          },
        ),
        verticalSpace(Spacing.points16),
        PlatformDatePicker(
          value: _dateOfBirth,
          onChanged: (date) {
            if (mounted) setState(() => _dateOfBirth = date);
          },
          hint: AppLocalizations.of(context).translate('date-of-birth'),
          firstDate: DateTime(1960),
          lastDate: DateTime(2015, 12, 31),
          dateFormatter: _formatDate,
        ),
        verticalSpace(Spacing.points16),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('gender'),
          options: [
            SegmentedButtonOption(value: 'male', translationKey: 'male'),
            SegmentedButtonOption(value: 'female', translationKey: 'female'),
          ],
          selectedOption: _selectedGender,
          onChanged: (option) {
            if (mounted) setState(() => _selectedGender = option);
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('preferences'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('preferences-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points24),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('preferred-language'),
          options: [
            SegmentedButtonOption(value: 'english', translationKey: 'english'),
            SegmentedButtonOption(value: 'arabic', translationKey: 'arabic'),
          ],
          selectedOption: _selectedLanguage,
          onChanged: (selection) {
            if (mounted) setState(() => _selectedLanguage = selection);
          },
        ),
      ],
    );
  }

  Widget _buildRecoverySetupContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('recovery-setup'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('recovery-setup-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points24),
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[200]!, width: 1),
          child: PlatformSwitch(
            value: _startFromNow,
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _startFromNow = value;
                  if (value) {
                    _startingDate = DateTime.now();
                  }
                });
              }
            },
            label: AppLocalizations.of(context).translate('start-from-now'),
            subtitle: _startFromNow
                ? _formatDateTime(DateTime.now())
                : AppLocalizations.of(context)
                    .translate('start-from-now-subtitle'),
          ),
        ),
        if (!_startFromNow) ...[
          verticalSpace(Spacing.points16),
          PlatformDatePicker(
            value: _startingDate,
            onChanged: (date) {
              if (mounted) setState(() => _startingDate = date);
            },
            hint:
                AppLocalizations.of(context).translate('select-starting-date'),
            label: AppLocalizations.of(context).translate('starting-date'),
            firstDate: DateTime(2022),
            lastDate: DateTime.now(),
            dateFormatter: _formatDateTime,
            mode: PlatformDatePickerMode.dateTime,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailVerificationContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('final-step'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('final-step-explanation'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points24),

        // Review collected information
        _buildRegistrationSummary(theme),

        // Terms and Conditions
        verticalSpace(Spacing.points32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (value) =>
                  setState(() => _termsAccepted = value ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(urlLauncherProvider).launch(
                        Uri.parse('https://www.ta3afi.app/ar/terms'),
                      );
                },
                child: Text(
                  AppLocalizations.of(context).translate('terms-acceptance'),
                  style: TextStyles.footnote.copyWith(
                    decoration: TextDecoration.underline,
                    color: theme.primary[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegistrationSummary(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('registration-summary'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points12),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('email'),
            _emailController.text,
            theme,
          ),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('first-name'),
            _nameController.text,
            theme,
          ),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('date-of-birth'),
            _dateOfBirth != null ? _formatDate(_dateOfBirth!) : '',
            theme,
          ),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('gender'),
            AppLocalizations.of(context)
                .translate(_selectedGender.translationKey),
            theme,
          ),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('preferred-language'),
            AppLocalizations.of(context)
                .translate(_selectedLanguage.translationKey),
            theme,
          ),
          _buildSummaryRow(
            AppLocalizations.of(context).translate('starting-date'),
            _startFromNow
                ? AppLocalizations.of(context).translate('start-from-now')
                : (_startingDate != null
                    ? _formatDateTime(_startingDate!)
                    : ''),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _isProcessing ? null : _previousStep,
                child: Text(
                  AppLocalizations.of(context).translate('back'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[600]),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isProcessing ? theme.grey[400] : theme.primary[600],
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.5),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Spinner(
                              strokeWidth: 2, valueColor: theme.grey[50]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('processing'),
                          style: TextStyles.footnote
                              .copyWith(color: theme.grey[50]),
                        ),
                      ],
                    )
                  : Text(
                      _currentStep == 4
                          ? AppLocalizations.of(context)
                              .translate('create-account')
                          : AppLocalizations.of(context).translate('continue'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
