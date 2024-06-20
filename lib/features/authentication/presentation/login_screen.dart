import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';
import 'package:reboot_app_3/providers/main_providers.dart';

class LogInScreen extends ConsumerWidget {
  const LogInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              verticalSpace(Spacing.points80),
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
              verticalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context).translate('login'),
                style: TextStyles.h2.copyWith(color: theme.primary[600]),
              ),
              verticalSpace(Spacing.points24),
              SignInForm(),
              verticalSpace(Spacing.points8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('forget-password'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.primary[600],
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).translate('sign-up'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.primary[600],
                    ),
                  )
                ],
              ),
              verticalSpace(Spacing.points16),
              WidgetsContainer(
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
              verticalSpace(Spacing.points24),
              Text(
                AppLocalizations.of(context).translate('or-login-with'),
                style: TextStyles.caption.copyWith(color: theme.primary[600]),
              ),
              verticalSpace(Spacing.points12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                  horizontalSpace(Spacing.points4),
                  Container(
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
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SignInForm extends ConsumerWidget {
  SignInForm({
    super.key,
  });

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CustomTextField(
          controller: passwordController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: emailController,
          obscureText: true,
          hint: AppLocalizations.of(context).translate('password'),
          prefixIcon: LucideIcons.lock,
          inputType: TextInputType.visiblePassword,
        ),
      ],
    );
  }
}

class CustomTextField extends ConsumerWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final TextInputType inputType;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const CustomTextField({
    Key? key,
    this.borderRadius,
    this.borderSide,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    required this.inputType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      decoration: ShapeDecoration(
        color: theme.grey[50],
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius:
                (borderRadius ?? BorderRadius.circular(10.5)).topLeft.x,
            cornerSmoothing: 1,
          ),
          side: borderSide ??
              BorderSide(
                color: theme.primary[200]!,
                width: 1.5,
              ),
        ),
      ),
      child: TextField(
        enabled: true,
        controller: controller,
        textCapitalization: textCapitalization,
        maxLength: 32,
        maxLines: 1,
        obscureText: obscureText,
        keyboardType: inputType,
        textAlign: TextAlign.start,
        style: TextStyles.footnote.copyWith(height: 3),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon),
          hintText: hint,
          counterText: "",
          hintStyle: TextStyles.footnote,
          border: InputBorder.none, // Remove default border
        ),
      ),
    );
  }
}
