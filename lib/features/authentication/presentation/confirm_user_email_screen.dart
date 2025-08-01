import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';

class ConfirmUserEmailScreen extends ConsumerStatefulWidget {
  const ConfirmUserEmailScreen({super.key});

  @override
  ConsumerState<ConfirmUserEmailScreen> createState() =>
      _ConfirmUserEmailScreenState();
}

class _ConfirmUserEmailScreenState
    extends ConsumerState<ConfirmUserEmailScreen> {
  int _currentStep = 0;
  bool _isResending = false;
  bool _isChecking = false;
  Timer? _verificationTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _currentEmail;
  bool _emailChangeInProgress = false; // Track if email change is in progress
  bool _showLogoutCountdown = false; // Track if showing logout countdown
  int _logoutCountdown = 10; // Countdown seconds

  @override
  void initState() {
    super.initState();
    _getCurrentEmail();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null && mounted) {
        // Only update email if we're NOT in the middle of an email change process
        // During email change, _currentEmail holds the NEW email we're trying to verify
        // while user.email still holds the OLD email until verification is complete
        if (!_emailChangeInProgress &&
            _currentEmail != null &&
            _currentEmail != user.email) {
          // Update Firestore user document with new email
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'email': user.email});

            // Update current email
            setState(() {
              _currentEmail = user.email;
            });

            // Refresh providers
            ref.invalidate(userDocumentsNotifierProvider);
            ref.invalidate(userNotifierProvider);
          } catch (e) {
            // Handle error silently or log it
            print('Error updating user document: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _getCurrentEmail() {
    _currentEmail = FirebaseAuth.instance.currentUser?.email;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      // Check if this was an email change verification
      if (_emailChangeInProgress) {
        // For email changes, check if the user's email in Firebase has been updated
        // to the new email we're expecting AND it's verified
        if (user?.email == _currentEmail && user?.emailVerified == true) {
          _verificationTimer?.cancel();

          // Reset the email change flag since verification is complete
          setState(() {
            _emailChangeInProgress = false;
          });

          if (mounted) {
            // Email change verification successful - show logout countdown
            setState(() {
              _showLogoutCountdown = true;
              _logoutCountdown = 10;
            });

            // Start countdown timer
            Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted) {
                setState(() {
                  _logoutCountdown--;
                });

                if (_logoutCountdown <= 0) {
                  timer.cancel();
                  // Log out the user for security - let router handle redirect
                  final authService = ref.read(authServiceProvider);
                  authService.signOut(context, ref);
                }
              } else {
                timer.cancel();
              }
            });
          }
        } else {
          // Email change not verified yet
          if (mounted) {
            getErrorSnackBar(context, 'email-change-not-verified-yet');
          }
        }
      } else {
        // Regular email verification (not a change)
        if (user?.emailVerified == true) {
          _verificationTimer?.cancel();
          ref.invalidate(accountStatusProvider);
          ref.invalidate(userNotifierProvider);

          if (mounted) {
            setState(() => _currentStep = 2);
            getSuccessSnackBar(context, 'email-verified-successfully');
          }
        } else {
          // Email is not verified yet - show warning snackbar
          if (mounted) {
            getErrorSnackBar(context, 'email-not-verified-yet');
          }
        }
      }
    } catch (e) {
      // Ignore errors during automatic check
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      if (_emailChangeInProgress) {
        // For email changes, we need to resend verification to the new email
        // This requires calling verifyBeforeUpdateEmail again
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && _currentEmail != null) {
          await currentUser.verifyBeforeUpdateEmail(_currentEmail!);
        }
      } else {
        // Regular email verification
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      }

      if (mounted) {
        getSuccessSnackBar(context, 'verification-email-sent');

        // Move to next step after sending email (only if not already there)
        if (_currentStep == 0) {
          setState(() {
            _currentStep = 1;
          });
        }

        // Start cooldown
        setState(() => _resendCooldown = 60);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCooldown > 0) {
            setState(() => _resendCooldown--);
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, 'failed-to-send-verification-email');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _showChangeEmailBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeEmailBottomSheet(
        onEmailChanged: (newEmail) {
          setState(() {
            _currentEmail = newEmail; // This is the NEW email we're verifying
            _emailChangeInProgress =
                true; // Mark that email change is in progress
            _currentStep =
                1; // Go directly to step 2 (check inbox) since email was sent
            _resendCooldown = 60; // Start cooldown since email was just sent
          });
          // Cancel any existing timers
          _cooldownTimer?.cancel();
          // Start cooldown timer
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) {
              if (_resendCooldown > 0) {
                setState(() => _resendCooldown--);
              } else {
                timer.cancel();
              }
            } else {
              timer.cancel();
            }
          });
          // Note: Don't invalidate userNotifierProvider here as it causes navigation issues
          // The auth state listener will automatically update when email change happens
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final userAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'confirm-email', _currentStep > 0, true),
      body: SafeArea(
        child: Stack(
          children: [
            userAsync.when(
              loading: () => const Center(child: Spinner()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (user) {
                if (user == null) {
                  return const Center(child: Text('User not found'));
                }

                // Only update current email from user data if we're not in email change process
                if (!_emailChangeInProgress && _currentEmail != user.email) {
                  _currentEmail = user.email;
                }

                return Column(
                  children: [
                    // Horizontal Step Indicator
                    _buildHorizontalStepIndicator(theme),
                    // Step Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildCurrentStepContent(theme),
                      ),
                    ),
                    // Controls
                    _buildControls(theme),
                  ],
                );
              },
            ),

            // Logout countdown overlay
            if (_showLogoutCountdown)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.checkCircle,
                          color: theme.success[600],
                          size: 64,
                        ),
                        verticalSpace(Spacing.points16),
                        Text(
                          AppLocalizations.of(context)
                              .translate('email-updated-successfully'),
                          style: TextStyles.h5.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        verticalSpace(Spacing.points12),
                        Text(
                          AppLocalizations.of(context)
                              .translate('logging-out-for-security'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        verticalSpace(Spacing.points24),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primary[300]!,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$_logoutCountdown',
                              style: TextStyles.h3.copyWith(
                                color: theme.primary[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalStepIndicator(dynamic theme) {
    const int totalSteps = 3;
    final stepLabels = [
      'send-email',
      'check-inbox',
      'verified',
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

  Widget _buildCurrentStepContent(dynamic theme) {
    switch (_currentStep) {
      case 0:
        return _buildSendEmailContent(theme);
      case 1:
        return _buildCheckInboxContent(theme);
      case 2:
        return _buildVerifiedContent(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSendEmailContent(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_unread_outlined,
          size: 80,
          color: theme.primary[600],
        ),
        verticalSpace(Spacing.points24),
        Text(
          AppLocalizations.of(context).translate('verify-your-email'),
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('confirm-email-banner'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points16),

        // Email display with change option
        Text(
          AppLocalizations.of(context).translate('current-email'),
          style: TextStyles.footnote.copyWith(
            color: theme.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primary[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.primary[200]!, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentEmail ?? '',
                style: TextStyles.footnote.copyWith(
                  color: theme.primary[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              GestureDetector(
                onTap: _showChangeEmailBottomSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.warn[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.warn[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.edit2,
                        color: theme.warn[700],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).translate('change'),
                        style: TextStyles.small.copyWith(
                          color: theme.warn[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        verticalSpace(Spacing.points16),
        // Warning for random emails
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.warn[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.warn[200]!, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: theme.warn[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .translate('verify-real-email-warning'),
                  style: TextStyles.small.copyWith(
                    color: theme.warn[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        verticalSpace(Spacing.points32),
        const UserIdContainer(),
      ],
    );
  }

  Widget _buildCheckInboxContent(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.mailCheck,
          size: 80,
          color: theme.success[600],
        ),
        verticalSpace(Spacing.points24),
        Text(
          AppLocalizations.of(context).translate('check-your-email'),
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points16),
        Text(
          _emailChangeInProgress
              ? AppLocalizations.of(context).translate('check-new-email-inbox')
              : AppLocalizations.of(context)
                  .translate('check-inbox-and-click-link'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.success[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.success[200]!, width: 1),
          ),
          child: Column(
            children: [
              if (_emailChangeInProgress) ...[
                Text(
                  AppLocalizations.of(context).translate('new-email'),
                  style: TextStyles.small.copyWith(
                    color: theme.success[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                verticalSpace(Spacing.points4),
              ],
              Text(
                _currentEmail ?? '',
                style: TextStyles.footnote.copyWith(
                  color: theme.success[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points24),
        // Resend email section and change email option
        if (_resendCooldown > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  color: theme.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context).translate('resend-in')} $_resendCooldown ${AppLocalizations.of(context).translate('seconds')}',
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

        verticalSpace(Spacing.points16),

        // Change email option (always available in step 2)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.warn[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.warn[200]!, width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    color: theme.warn[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)
                        .translate('wrong-email-question'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.warn[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points8),
              GestureDetector(
                onTap: _showChangeEmailBottomSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.warn[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.warn[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.edit2,
                        color: theme.warn[700],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).translate('change-email'),
                        style: TextStyles.footnote.copyWith(
                          color: theme.warn[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedContent(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.checkCircle,
          size: 80,
          color: theme.success[600],
        ),
        verticalSpace(Spacing.points24),
        Text(
          AppLocalizations.of(context).translate('email-verified'),
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('email-verified-successfully'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControls(dynamic theme) {
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
          if (_currentStep > 0 && _currentStep < 2)
            Expanded(
              child: TextButton(
                onPressed: _previousStep,
                child: Text(
                  AppLocalizations.of(context).translate('back'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[600]),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildPrimaryButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(dynamic theme) {
    switch (_currentStep) {
      case 0:
        return ElevatedButton(
          onPressed: _isResending ? null : _resendVerificationEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isResending ? theme.grey[400] : theme.primary[600],
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.5),
            ),
          ),
          child: _isResending
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          Spinner(strokeWidth: 2, valueColor: theme.grey[50]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('sending'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
                  ],
                )
              : Text(
                  AppLocalizations.of(context).translate('confirm-email'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[50]),
                ),
        );
      case 1:
        return ElevatedButton(
          onPressed: _isChecking ? null : _checkEmailVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isChecking ? theme.grey[400] : theme.success[600],
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.5),
            ),
          ),
          child: _isChecking
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          Spinner(strokeWidth: 2, valueColor: theme.grey[50]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('checking'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.checkCircle,
                      color: theme.grey[50],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('check-verification-status'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[50]),
                    ),
                  ],
                ),
        );
      case 2:
        return ElevatedButton(
          onPressed: () => context.goNamed(RouteNames.home.name),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.success[600],
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.5),
            ),
          ),
          child: Text(
            AppLocalizations.of(context).translate('continue'),
            style: TextStyles.footnote.copyWith(color: theme.grey[50]),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

class ChangeEmailBottomSheet extends ConsumerStatefulWidget {
  const ChangeEmailBottomSheet({
    required this.onEmailChanged,
    super.key,
  });

  final Function(String) onEmailChanged;

  @override
  ConsumerState<ChangeEmailBottomSheet> createState() =>
      _ChangeEmailBottomSheetState();
}

class _ChangeEmailBottomSheetState
    extends ConsumerState<ChangeEmailBottomSheet> {
  final TextEditingController _currentEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill current email
    _currentEmailController.text =
        FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _currentEmailController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      // Check if email exists in Firestore users collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If error occurs, assume email doesn't exist
      return false;
    }
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final currentEmail = _currentEmailController.text.trim();
      final password = _passwordController.text.trim();
      final newEmail = _newEmailController.text.trim();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Check if new email already exists
      final emailExists = await _checkEmailExists(newEmail);
      if (emailExists) {
        if (mounted) {
          getErrorSnackBar(context, 'email-already-exists');
        }
        return;
      }

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);

      // Update Firebase Auth email using the recommended method
      // This will send a verification email to the new address
      await currentUser.verifyBeforeUpdateEmail(newEmail);

      // Note: We only update Firestore after email is verified
      // For now, we show success message that verification email was sent
      // Don't invalidate providers here as it can cause navigation issues

      if (mounted) {
        // Show verification sent message
        getSuccessSnackBar(context, 'email-verification-sent-check-junk');
        Navigator.pop(context);

        // Update the callback to notify parent that email verification was sent
        widget.onEmailChanged(newEmail);
      }
    } catch (e) {
      if (mounted) {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              getErrorSnackBar(context, 'wrong-password');
              break;
            case 'invalid-email':
              getErrorSnackBar(context, 'invalid-email');
              break;
            case 'user-not-found':
              getErrorSnackBar(context, 'user-not-found');
              break;
            case 'too-many-requests':
              getErrorSnackBar(context, 'too-many-requests');
              break;
            case 'requires-recent-login':
              getErrorSnackBar(context, 'requires-recent-login');
              break;
            default:
              getErrorSnackBar(context, 'email-update-failed');
          }
        } else {
          getErrorSnackBar(context, 'email-update-failed');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('change-email'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  LucideIcons.x,
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('change-email-description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.warn[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.warn[200]!, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  color: theme.warn[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('email-change-signout-warning'),
                    style: TextStyles.small.copyWith(
                      color: theme.warn[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          verticalSpace(Spacing.points16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Current Email Field
                CustomTextField(
                  controller: _currentEmailController,
                  hint: AppLocalizations.of(context).translate('current-email'),
                  prefixIcon: LucideIcons.mail,
                  inputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)
                          .translate('field-required');
                    }
                    if (!AppRegex.isEmailValid(value)) {
                      return AppLocalizations.of(context)
                          .translate('invalid-email');
                    }
                    return null;
                  },
                ),
                verticalSpace(Spacing.points12),

                // Password Field with built-in toggle
                CustomTextField(
                  controller: _passwordController,
                  hint: AppLocalizations.of(context).translate('password'),
                  prefixIcon: LucideIcons.lock,
                  obscureText: true,
                  showObscureToggle: true,
                  inputType: TextInputType.visiblePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)
                          .translate('field-required');
                    }
                    return null;
                  },
                ),
                verticalSpace(Spacing.points12),

                // New Email Field
                CustomTextField(
                  controller: _newEmailController,
                  hint: AppLocalizations.of(context).translate('new-email'),
                  prefixIcon: LucideIcons.mailPlus,
                  inputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)
                          .translate('field-required');
                    }
                    if (!AppRegex.isEmailValid(value)) {
                      return AppLocalizations.of(context)
                          .translate('invalid-email');
                    }
                    if (value == _currentEmailController.text.trim()) {
                      return AppLocalizations.of(context)
                          .translate('new-email-same-as-current');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          verticalSpace(Spacing.points24),
          GestureDetector(
            onTap: _isUpdating
                ? null
                : () async {
                    await _updateEmail();
                  },
            child: WidgetsContainer(
              backgroundColor:
                  _isUpdating ? theme.grey[400] : theme.primary[600],
              width: double.infinity,
              child: Center(
                child: _isUpdating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Spinner(
                                strokeWidth: 2, valueColor: theme.grey[50]!),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).translate('updating'),
                            style: TextStyles.footnote
                                .copyWith(color: theme.grey[50]),
                          ),
                        ],
                      )
                    : Text(
                        AppLocalizations.of(context).translate('update-email'),
                        style:
                            TextStyles.footnote.copyWith(color: theme.grey[50]),
                      ),
              ),
            ),
          ),
          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }
}

// Add the new UserIdContainer widget before the main screen class
class UserIdContainer extends ConsumerWidget {
  const UserIdContainer({super.key});

  Future<void> _copyUserIdToClipboard(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Clipboard.setData(ClipboardData(text: user.uid));
      if (context.mounted) {
        getSuccessSnackBar(context, 'user-id-copied');
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, WidgetRef ref) async {
    const phoneNumber = '96876691799';
    final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    final urlLauncher = ref.read(urlLauncherProvider);

    try {
      await urlLauncher.launch(whatsappUrl);
    } on UrlLauncherException {
      if (context.mounted) {
        getErrorSnackBar(context, 'whatsapp-error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[100]!,
        width: 1,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User ID Section
          Row(
            children: [
              Icon(
                LucideIcons.user,
                color: theme.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('user-id'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user.uid,
                    style: TextStyles.small.copyWith(
                      color: theme.grey[800],
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyUserIdToClipboard(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primary[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.copy,
                      color: theme.primary[600],
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: theme.grey[200],
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),

          const SizedBox(height: 12),

          // WhatsApp Contact Section
          GestureDetector(
            onTap: () => _launchWhatsApp(context, ref),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.3),
                    width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    color: const Color(0xFF25D366),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('contact-support'),
                          style: TextStyles.footnote.copyWith(
                            color: const Color(0xFF25D366),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)
                              .translate('contact-through-whatsapp'),
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.externalLink,
                    color: const Color(0xFF25D366),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
