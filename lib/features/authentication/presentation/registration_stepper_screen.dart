import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
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
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';

class RegistrationStepperScreen extends ConsumerStatefulWidget {
  const RegistrationStepperScreen({super.key});

  @override
  ConsumerState<RegistrationStepperScreen> createState() =>
      _RegistrationStepperScreenState();
}

class _RegistrationStepperScreenState
    extends ConsumerState<RegistrationStepperScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isProcessing = false;

  // Step 1: Personal Information
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dateOfBirth;

  // Step 2: Preferences
  SegmentedButtonOption _selectedGender =
      SegmentedButtonOption(value: 'male', translationKey: 'male');
  SegmentedButtonOption _selectedLanguage =
      SegmentedButtonOption(value: 'english', translationKey: 'english');

  // Step 3: Recovery Setup
  DateTime? _startingDate;
  bool _startFromNow = false;
  bool _termsAccepted = false;

  // Step 4: Email Verification
  bool _isResending = false;
  bool _isChecking = false;
  Timer? _verificationTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _emailVerified = user.emailVerified;

      // Check if this is an OAuth user with already verified email
      if (user.emailVerified) {
        // For OAuth users, email is already verified
        _emailVerified = true;
      }
    }
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
      case 0: // Personal Information
        if (_nameController.text.trim().isEmpty) {
          getErrorSnackBar(context, 'name-required');
          return false;
        }
        if (_emailController.text.trim().isEmpty ||
            !AppRegex.isEmailValid(_emailController.text.trim())) {
          getErrorSnackBar(context, 'valid-email-required');
          return false;
        }
        if (_dateOfBirth == null ||
            _dateOfBirth!.isAfter(DateTime(2010, 12, 31))) {
          getErrorSnackBar(context, 'valid-birth-date-required');
          return false;
        }
        return true;

      case 1: // Preferences
        return true; // Always valid as we have defaults

      case 2: // Recovery Setup
        if (_startingDate == null && !_startFromNow) {
          getErrorSnackBar(context, 'starting-date-required');
          return false;
        }
        if (!_termsAccepted) {
          getErrorSnackBar(context, 'terms-acceptance-required');
          return false;
        }
        return true;

      case 3: // Email Verification
        // Check if email is already verified (OAuth users) or user has verified it
        final user = FirebaseAuth.instance.currentUser;
        return _emailVerified || (user?.emailVerified == true);

      default:
        return true;
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 2) {
      // Complete registration before moving to email verification
      await _completeRegistration();
    } else if (_currentStep < 4) {
      if (mounted) setState(() => _currentStep++);
      if (_currentStep == 3 && mounted) {
        // Check if email is already verified (OAuth users)
        final user = FirebaseAuth.instance.currentUser;
        if (user?.emailVerified == true) {
          if (mounted) setState(() => _emailVerified = true);
        } else {
          _sendVerificationEmail();
        }
      }
    } else {
      // Final step - navigate to home
      if (mounted) context.goNamed(RouteNames.home.name);
    }
  }

  void _previousStep() {
    if (_currentStep > 0 && mounted) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeRegistration() async {
    if (mounted) setState(() => _isProcessing = true);

    try {
      final authService = ref.read(authServiceProvider);
      final finalStartingDate = _startFromNow ? DateTime.now() : _startingDate!;

      await authService.completeAccountRegiseration(
        context,
        _nameController.text.trim(),
        _dateOfBirth!,
        _selectedGender.value,
        _selectedLanguage.value,
        finalStartingDate,
      );

      unawaited(ref.read(analyticsFacadeProvider).trackOnboardingFinish());
      await ref.refresh(userDocumentsNotifierProvider.future);

      if (mounted) setState(() => _currentStep++);
      if (mounted) _sendVerificationEmail();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      if (mounted) getErrorSnackBar(context, 'registration-failed');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isResending) return;

    if (mounted) setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) getSuccessSnackBar(context, 'verification-email-sent');

      if (mounted) setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          if (mounted) setState(() => _resendCooldown--);
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) getErrorSnackBar(context, 'verification-email-failed');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;

    if (mounted) setState(() => _isChecking = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified == true) {
        if (mounted) setState(() => _emailVerified = true);
        if (mounted) getSuccessSnackBar(context, 'email-verified-successfully');
      } else {
        if (mounted) getErrorSnackBar(context, 'email-not-verified-yet');
      }
    } catch (e) {
      if (mounted) getErrorSnackBar(context, 'verification-check-failed');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final userAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'setup-account', _currentStep > 0, true),
      body: userAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (user) => _buildStepper(context, theme),
      ),
    );
  }

  Widget _buildStepper(BuildContext context, dynamic theme) {
    return Form(
      key: _formKey,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: theme.primary[600]!,
            primary: theme.primary[600]!,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            // Only allow going back or staying on current step
            if (step <= _currentStep && mounted) {
              setState(() => _currentStep = step);
            }
          },
          controlsBuilder: (context, details) => _buildControls(details),
          steps: [
            _buildPersonalInfoStep(),
            _buildPreferencesStep(),
            _buildRecoverySetupStep(),
            _buildEmailVerificationStep(),
            _buildCompletionStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ControlsDetails details) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
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
                          ? AppLocalizations.of(context).translate('finish')
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

  Step _buildPersonalInfoStep() {
    final theme = AppTheme.of(context);

    return Step(
      title: Text(
        AppLocalizations.of(context).translate('personal-information'),
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('personal-info-explanation'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points16),
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
          verticalSpace(Spacing.points12),
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
          verticalSpace(Spacing.points12),
          PlatformDatePicker(
            value: _dateOfBirth,
            onChanged: (date) {
              if (mounted) setState(() => _dateOfBirth = date);
            },
            hint: AppLocalizations.of(context).translate('date-of-birth'),
            label: AppLocalizations.of(context).translate('date-of-birth'),
            firstDate: DateTime(1960),
            lastDate: DateTime(2010, 12, 31),
            dateFormatter: _formatDate,
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildPreferencesStep() {
    final theme = AppTheme.of(context);

    return Step(
      title: Text(
        AppLocalizations.of(context).translate('preferences'),
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('preferences-explanation'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points16),
          CustomSegmentedButton(
            label: AppLocalizations.of(context).translate('gender'),
            options: [
              SegmentedButtonOption(value: 'male', translationKey: 'male'),
              SegmentedButtonOption(value: 'female', translationKey: 'female'),
            ],
            selectedOption: _selectedGender,
            onChanged: (selection) {
              if (mounted) setState(() => _selectedGender = selection);
            },
          ),
          verticalSpace(Spacing.points16),
          CustomSegmentedButton(
            label: AppLocalizations.of(context).translate('preferred-language'),
            options: [
              SegmentedButtonOption(
                  value: 'english', translationKey: 'english'),
              SegmentedButtonOption(value: 'arabic', translationKey: 'arabic'),
            ],
            selectedOption: _selectedLanguage,
            onChanged: (selection) {
              if (mounted) setState(() => _selectedLanguage = selection);
            },
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildRecoverySetupStep() {
    final theme = AppTheme.of(context);

    return Step(
      title: Text(
        AppLocalizations.of(context).translate('recovery-setup'),
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .translate('recovery-setup-explanation'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points16),
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
            verticalSpace(Spacing.points12),
            PlatformDatePicker(
              value: _startingDate,
              onChanged: (date) {
                if (mounted) setState(() => _startingDate = date);
              },
              hint: AppLocalizations.of(context)
                  .translate('select-starting-date'),
              label: AppLocalizations.of(context).translate('starting-date'),
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
              dateFormatter: _formatDateTime,
              mode: PlatformDatePickerMode.dateTime,
            ),
          ],
          verticalSpace(Spacing.points16),
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
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildEmailVerificationStep() {
    final theme = AppTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isEmailAlreadyVerified = user?.emailVerified == true;

    return Step(
      title: Text(
        AppLocalizations.of(context).translate('email-verification'),
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              isEmailAlreadyVerified
                  ? LucideIcons.checkCircle
                  : LucideIcons.mail,
              color: isEmailAlreadyVerified
                  ? theme.success[600]
                  : theme.primary[600],
              size: 80,
            ),
          ),
          verticalSpace(Spacing.points16),
          Text(
            isEmailAlreadyVerified
                ? AppLocalizations.of(context)
                    .translate('email-already-verified-explanation')
                : AppLocalizations.of(context)
                    .translate('email-verification-explanation'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points8),
          Text(
            isEmailAlreadyVerified
                ? '${AppLocalizations.of(context).translate('verified-email')} ${_emailController.text}'
                : '${AppLocalizations.of(context).translate('verification-sent-to')} ${_emailController.text}',
            style: TextStyles.footnote.copyWith(
              color:
                  isEmailAlreadyVerified ? theme.success[600] : theme.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points24),

          // Show different buttons based on verification status
          if (isEmailAlreadyVerified) ...[
            // Already verified - show success message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.success[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.success[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle,
                      color: theme.success[600], size: 20),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('email-verified-oauth-message'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.success[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Not verified - show verification buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkEmailVerification,
                icon: _isChecking
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child:
                            Spinner(strokeWidth: 2, valueColor: theme.grey[50]),
                      )
                    : Icon(LucideIcons.checkCircle,
                        color: theme.grey[50], size: 16),
                label: Text(
                  AppLocalizations.of(context).translate('check-verification'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[50]),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            verticalSpace(Spacing.points12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resendCooldown > 0 ? null : _sendVerificationEmail,
                icon: _isResending
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: Spinner(
                            strokeWidth: 2, valueColor: theme.primary[600]),
                      )
                    : Icon(LucideIcons.mail,
                        color: theme.primary[600], size: 16),
                label: Text(
                  _resendCooldown > 0
                      ? '${AppLocalizations.of(context).translate('resend-in')} $_resendCooldown ${AppLocalizations.of(context).translate('seconds')}'
                      : AppLocalizations.of(context)
                          .translate('resend-verification'),
                  style:
                      TextStyles.footnote.copyWith(color: theme.primary[600]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primary[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }

  Step _buildCompletionStep() {
    final theme = AppTheme.of(context);

    return Step(
      title: Text(
        AppLocalizations.of(context).translate('all-set'),
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              LucideIcons.checkCircle,
              color: theme.success[600],
              size: 100,
            ),
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('registration-complete'),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('welcome-message'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      isActive: _currentStep >= 4,
    );
  }
}
