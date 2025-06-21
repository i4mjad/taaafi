import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LogInScreen extends ConsumerWidget {
  const LogInScreen({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _showError(BuildContext context, String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate(message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final theme = AppTheme.of(context);
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, 'login', true, true),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: theme.primary[50],
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          width: 2,
                          color: theme.grey[100]!,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.user2,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points36),
                SignInForm(),
                verticalSpace(Spacing.points24),
                Text(
                  AppLocalizations.of(context).translate('or-login-with'),
                  style: TextStyles.caption.copyWith(color: theme.primary[600]),
                ),
                verticalSpace(Spacing.points12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        if (!Platform.isIOS) {
                          _showError(context, "cannot-login-with-apple");
                          return;
                        }
                        unawaited(
                            ref.read(analyticsFacadeProvider).trackUserLogin());
                        try {
                          final user =
                              await authService.signInWithApple(context);
                          if (user != null) {
                            FirebaseCrashlytics.instance
                                .setUserIdentifier(user.uid);
                            FirebaseAnalytics.instance.setUserId(id: user.uid);
                          }
                        } catch (e) {
                          _showError(context, e.toString());
                        }
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: theme.primary[50],
                            borderRadius: BorderRadius.circular(150),
                            border: Border.all(
                              color: theme.primary[100]!,
                              width: 1,
                            )),
                        child: SvgPicture.asset(
                          'asset/icons/apple-icon.svg',
                          semanticsLabel: 'Apple Logo',
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points4),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        unawaited(
                            ref.read(analyticsFacadeProvider).trackUserLogin());
                        try {
                          final user =
                              await authService.signInWithGoogle(context);
                          if (user != null) {
                            FirebaseCrashlytics.instance
                                .setUserIdentifier(user.uid);
                            FirebaseAnalytics.instance.setUserId(id: user.uid);
                          }
                        } catch (e) {
                          _showError(context, e.toString());
                        }
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: theme.primary[50],
                            borderRadius: BorderRadius.circular(150),
                            border: Border.all(
                              color: theme.primary[100]!,
                              width: 1,
                            )),
                        child: SvgPicture.asset(
                          'asset/icons/google-icon.svg',
                          semanticsLabel: 'Google Logo',
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignInForm extends ConsumerWidget {
  SignInForm({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final authService = ref.watch(authServiceProvider);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: emailController,
            hint: AppLocalizations.of(context).translate('email'),
            prefixIcon: LucideIcons.mail,
            inputType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context).translate('cant-be-empty');
              }

              if (!AppRegex.isEmailValid(value)) {
                return AppLocalizations.of(context).translate('invalid-email');
              }
              return null;
            },
          ),
          verticalSpace(Spacing.points8),
          CustomTextField(
            controller: passwordController,
            obscureText: true,
            showObscureToggle: true,
            hint: AppLocalizations.of(context).translate('password'),
            prefixIcon: LucideIcons.lock,
            inputType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context).translate('cant-be-empty');
              }
              return null;
            },
          ),
          verticalSpace(Spacing.points8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(RouteNames.forgotPassword.name);
                },
                child: Text(
                  AppLocalizations.of(context).translate('forget-password'),
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.primary[600],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(RouteNames.signup.name);
                },
                child: Text(
                  AppLocalizations.of(context).translate('sign-up'),
                  style: TextStyles.footnoteSelected
                      .copyWith(color: theme.primary[600]),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final email = emailController.value.text;
              final password = passwordController.value.text;

              if (_formKey.currentState!.validate()) {
                unawaited(ref.read(analyticsFacadeProvider).trackUserLogin());
                try {
                  final user = await authService.signInWithEmail(
                    context,
                    email,
                    password,
                  );
                  if (user != null) {
                    await Sentry.configureScope(
                      (scope) => scope.setUser(SentryUser(id: user.uid)),
                    );
                  }
                } catch (e) {
                  LogInScreen.scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context).translate(e.toString())),
                    ),
                  );
                }
              }
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[600],
              width: MediaQuery.of(context).size.width - (16 + 16),
              padding: EdgeInsets.only(top: 12, bottom: 12),
              borderRadius: BorderRadius.circular(10.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('login'),
                    style: TextStyles.footnoteSelected
                        .copyWith(color: theme.grey[50]),
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
