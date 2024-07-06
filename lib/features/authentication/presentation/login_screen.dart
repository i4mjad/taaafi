import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';

class LogInScreen extends ConsumerWidget {
  const LogInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'login', true),
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
                      color: theme.grey[50],
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
                      await authRepository.signInWithApple(context);
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
                      await authRepository.signInWithGoogle(context);
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
    );
  }
}

class SignInForm extends ConsumerStatefulWidget {
  SignInForm({
    super.key,
  });

  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    final authRepositoryNotifier = ref.watch(authRepositoryProvider);
    return Column(
      children: [
        CustomTextField(
          controller: emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: passwordController,
          obscureText: true,
          hint: AppLocalizations.of(context).translate('password'),
          prefixIcon: LucideIcons.lock,
          inputType: TextInputType.visiblePassword,
        ),
        verticalSpace(Spacing.points8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.goNamed(RouteNames.forgotPassword.name),
              child: Text(
                AppLocalizations.of(context).translate('forget-password'),
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.primary[600],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.goNamed(RouteNames.signup.name),
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
            final email = emailController.value.text;
            final password = passwordController.value.text;
            //TODO: validate before sending
            await authRepositoryNotifier.signInWithEmail(
              context,
              email,
              password,
            );
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
    );
  }
}
