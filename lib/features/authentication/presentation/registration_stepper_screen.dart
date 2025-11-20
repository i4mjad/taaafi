import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/referral/presentation/widgets/referral_code_input_widget.dart';

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
            _dateOfBirth!.isAfter(DateTime(2015, 12, 31))) {
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
        return true;

      case 3: // Email Verification
        // Check if terms are accepted
        if (!_termsAccepted) {
          getErrorSnackBar(context, 'terms-acceptance-required');
          return false;
        }
        // Check if email is already verified (OAuth users) or user has verified it
        final user = FirebaseAuth.instance.currentUser;
        return _emailVerified || (user?.emailVerified == true);

      case 4: // Referral Code (Optional - always valid)
        return true;

      default:
        return true;
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 5) {
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
      // Final step - complete registration and navigate to subscription
      await _completeRegistration();
      if (mounted) {
        context.goNamed(RouteNames.ta3afiPlus.name);
      }
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
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      if (mounted) getErrorSnackBar(context, 'registration-failed');
      rethrow; // Rethrow to prevent navigation to home on error
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
    );
  }

  Widget _buildHorizontalStepIndicator(dynamic theme) {
    const int totalSteps = 6;

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
                                  size: 16,
                                  color: theme.grey[50],
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyles.footnote.copyWith(
                                    color: isActive
                                        ? theme.primary[600]
                                        : theme.grey[600],
                                    fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 8),
                  // Step label
                  Text(
                    _getStepLabel(index),
                    style: TextStyles.caption.copyWith(
                      color: isActive
                          ? theme.primary[600]
                          : isCompleted
                              ? theme.grey[700]
                              : theme.grey[500],
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return AppLocalizations.of(context).translate('personal-info');
      case 1:
        return AppLocalizations.of(context).translate('preferences');
      case 2:
        return AppLocalizations.of(context).translate('recovery');
      case 3:
        return AppLocalizations.of(context).translate('verification');
      case 4:
        return AppLocalizations.of(context).translate('complete');
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoContent();
      case 1:
        return _buildPreferencesContent();
      case 2:
        return _buildRecoverySetupContent();
      case 3:
        return _buildEmailVerificationContent();
      case 4:
        return _buildReferralCodeContent();
      case 5:
        return _buildCompletionContent();
      default:
        return Container();
    }
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
                              .translate('referral.input.skip')
                          : _currentStep == 5
                              ? AppLocalizations.of(context).translate('finish')
                              : AppLocalizations.of(context)
                                  .translate('continue'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
            ),
          ),
        ],
      ),
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
        CustomTextField(
          controller: _emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          enabled: false,
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
        PlatformDatePicker(
          value: _dateOfBirth,
          onChanged: (date) {
            if (mounted) setState(() => _dateOfBirth = date);
          },
          hint: AppLocalizations.of(context).translate('date-of-birth'),
          // label: AppLocalizations.of(context).translate('date-of-birth'),
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
    final user = FirebaseAuth.instance.currentUser;
    final isEmailAlreadyVerified = user?.emailVerified == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('email-verification'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points24),
        Center(
          child: Icon(
            isEmailAlreadyVerified ? LucideIcons.checkCircle : LucideIcons.mail,
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
                  : Icon(LucideIcons.mail, color: theme.primary[600], size: 16),
              label: Text(
                _resendCooldown > 0
                    ? '${AppLocalizations.of(context).translate('resend-in')} $_resendCooldown ${AppLocalizations.of(context).translate('seconds')}'
                    : AppLocalizations.of(context)
                        .translate('resend-verification'),
                style: TextStyles.footnote.copyWith(color: theme.primary[600]),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primary[600]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

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

  Widget _buildReferralCodeContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          AppLocalizations.of(context).translate('referral.input.title'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points12),

        // Subtitle
        Text(
          AppLocalizations.of(context).translate('referral.input.subtitle'),
          style: TextStyles.footnote.copyWith(
            color: theme.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points32),

        // Referral code input widget
        ReferralCodeInputWidget(
          onSuccess: () {
            // Move to next step on success
            if (mounted) setState(() => _currentStep++);
          },
          onSkip: null, // No skip button - use the main "Skip" button instead
        ),
      ],
    );
  }

  Widget _buildCompletionContent() {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('all-set'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points24),
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
    );
  }
}
