import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';

// Global flag to track deletion login context
class DeletionLoginContext {
  static bool _isDeletionLogin = false;
  static DateTime? _loginTimestamp;

  static void setDeletionLogin() {
    _isDeletionLogin = true;
    _loginTimestamp = DateTime.now();
  }

  static bool isDeletionLogin() {
    if (!_isDeletionLogin || _loginTimestamp == null) {
      return false;
    }

    // Check if the flag is still valid (within 2 minutes)
    final now = DateTime.now();
    final isValid = now.difference(_loginTimestamp!).inMinutes < 2;

    if (!isValid) {
      clear();
    }

    return isValid;
  }

  static void clear() {
    _isDeletionLogin = false;
    _loginTimestamp = null;
  }
}

class AccountDeletionLoginScreen extends ConsumerStatefulWidget {
  const AccountDeletionLoginScreen({super.key});

  @override
  _AccountDeletionLoginScreenState createState() =>
      _AccountDeletionLoginScreenState();
}

class _AccountDeletionLoginScreenState
    extends ConsumerState<AccountDeletionLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _storeDeletionContext();
  }

  void _storeDeletionContext() {
    // Store that this login is for account deletion
    DeletionLoginContext.setDeletionLogin();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _navigateToLoadingScreen() {
    print('DEBUG: Navigating back to account deletion loading screen');

    // Clear the deletion context flag
    DeletionLoginContext.clear();

    // Navigate back to the loading screen to continue deletion process
    context.goNamed(RouteNames.accountDeletionLoading.name);
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final email = emailController.text.trim();
      final password = passwordController.text;

      print(
          'DEBUG: Attempting sign-in for account deletion with email: $email');

      final user = await authService.signInWithEmail(context, email, password);

      if (user != null) {
        print('DEBUG: Sign-in successful, proceeding to deletion');
        HapticFeedback.mediumImpact();

        // Small delay to ensure auth state is updated
        await Future.delayed(Duration(milliseconds: 300));

        if (mounted) {
          _navigateToLoadingScreen();
        }
      } else {
        print('DEBUG: Sign-in failed');
      }
    } catch (e) {
      print('ERROR: Sign-in failed: $e');
      if (mounted) {
        getErrorSnackBar(context, 'sign-in-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      print('DEBUG: Attempting Google sign-in for account deletion');

      final user = await authService.signInWithGoogle(context);

      if (user != null) {
        print('DEBUG: Google sign-in successful, proceeding to deletion');
        HapticFeedback.mediumImpact();

        // Small delay to ensure auth state is updated
        await Future.delayed(Duration(milliseconds: 300));

        if (mounted) {
          _navigateToLoadingScreen();
        }
      } else {
        print('DEBUG: Google sign-in failed');
      }
    } catch (e) {
      print('ERROR: Google sign-in failed: $e');
      if (mounted) {
        getErrorSnackBar(context, 'sign-in-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      print('DEBUG: Attempting Apple sign-in for account deletion');

      final user = await authService.signInWithApple(context);

      if (user != null) {
        print('DEBUG: Apple sign-in successful, proceeding to deletion');
        HapticFeedback.mediumImpact();

        // Small delay to ensure auth state is updated
        await Future.delayed(Duration(milliseconds: 300));

        if (mounted) {
          _navigateToLoadingScreen();
        }
      } else {
        print('DEBUG: Apple sign-in failed');
      }
    } catch (e) {
      print('ERROR: Apple sign-in failed: $e');
      if (mounted) {
        getErrorSnackBar(context, 'sign-in-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'confirm-identity-deletion', false, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.error[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.error[200]!, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: theme.error[600],
                      size: 32,
                    ),
                    verticalSpace(Spacing.points12),
                    Text(
                      AppLocalizations.of(context)
                          .translate('account-deletion-security-notice'),
                      style: TextStyles.h6.copyWith(
                        color: theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('account-deletion-security-description'),
                      style: TextStyles.body.copyWith(
                        color: theme.error[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              verticalSpace(Spacing.points32),

              // Email/Password Form
              WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[300]!, width: 1),
                boxShadow: [],
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('sign-in-with-email'),
                        style: TextStyles.h6.copyWith(
                          color: theme.primary[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      verticalSpace(Spacing.points16),
                      CustomTextField(
                        controller: emailController,
                        hint: AppLocalizations.of(context).translate('email'),
                        prefixIcon: LucideIcons.mail,
                        inputType: TextInputType.emailAddress,
                        enabled: !_isProcessing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('cant-be-empty');
                          }
                          return null;
                        },
                      ),
                      verticalSpace(Spacing.points12),
                      CustomTextField(
                        controller: passwordController,
                        obscureText: true,
                        showObscureToggle: true,
                        hint:
                            AppLocalizations.of(context).translate('password'),
                        prefixIcon: LucideIcons.lock,
                        inputType: TextInputType.visiblePassword,
                        enabled: !_isProcessing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('cant-be-empty');
                          }
                          return null;
                        },
                      ),
                      verticalSpace(Spacing.points20),
                      GestureDetector(
                        onTap: _isProcessing ? null : _signInWithEmail,
                        child: WidgetsContainer(
                          backgroundColor: _isProcessing
                              ? theme.grey[400]
                              : theme.error[600],
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          borderSide:
                              BorderSide(width: 0, color: theme.error[900]!),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isProcessing) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Spinner(),
                                ),
                                horizontalSpace(Spacing.points8),
                              ] else ...[
                                Icon(
                                  LucideIcons.logIn,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                horizontalSpace(Spacing.points8),
                              ],
                              Text(
                                _isProcessing
                                    ? AppLocalizations.of(context)
                                        .translate('signing-in')
                                    : AppLocalizations.of(context)
                                        .translate('sign-in-and-delete'),
                                style: TextStyles.footnoteSelected
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              verticalSpace(Spacing.points24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: theme.grey[300])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context).translate('or'),
                      style:
                          TextStyles.caption.copyWith(color: theme.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.grey[300])),
                ],
              ),

              verticalSpace(Spacing.points24),

              // Social Sign-in Options
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _signInWithApple,
                      child: WidgetsContainer(
                        backgroundColor: _isProcessing
                            ? theme.grey[200]
                            : theme.backgroundColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        borderSide:
                            BorderSide(color: theme.grey[400]!, width: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Spinner(strokeWidth: 2),
                              )
                            else
                              SvgPicture.asset(
                                'asset/icons/apple-icon.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  theme.primary[900]!,
                                  BlendMode.srcIn,
                                ),
                              ),
                            horizontalSpace(Spacing.points8),
                            Text(
                              AppLocalizations.of(context).translate('apple'),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: theme.primary[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _signInWithGoogle,
                      child: WidgetsContainer(
                        backgroundColor: _isProcessing
                            ? theme.grey[200]
                            : theme.backgroundColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        borderSide:
                            BorderSide(color: theme.grey[400]!, width: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Spinner(strokeWidth: 2),
                              )
                            else
                              SvgPicture.asset(
                                'asset/icons/google-icon.svg',
                                width: 20,
                                height: 20,
                              ),
                            horizontalSpace(Spacing.points8),
                            Text(
                              AppLocalizations.of(context).translate('google'),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: theme.primary[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              verticalSpace(Spacing.points32),

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: _isProcessing ? null : () => context.pop(),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
