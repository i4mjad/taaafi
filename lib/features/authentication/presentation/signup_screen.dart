import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              verticalSpace(Spacing.points40),
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
                        LucideIcons.userPlus,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context).translate('sign-up'),
                style: TextStyles.h2.copyWith(color: theme.primary[600]),
              ),
              verticalSpace(Spacing.points24),
              SignUpForm(),
              verticalSpace(Spacing.points8),
              WidgetsContainer(
                backgroundColor: theme.primary[600],
                width: MediaQuery.of(context).size.width - (16 + 16),
                padding: EdgeInsets.only(top: 12, bottom: 12),
                borderRadius: BorderRadius.circular(10.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('sign-up'),
                      style: TextStyles.footnoteSelected
                          .copyWith(color: theme.grey[50]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpForm extends ConsumerStatefulWidget {
  SignUpForm({
    super.key,
  });

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String selectedGender = 'Male';
  String selectedLanguage = 'English';

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: nameController,
          hint: AppLocalizations.of(context).translate('name'),
          prefixIcon: LucideIcons.user,
          inputType: TextInputType.name,
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: dobController,
          hint: AppLocalizations.of(context).translate('date-of-birth'),
          prefixIcon: LucideIcons.calendar,
          inputType: TextInputType.datetime,
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('gender'),
          options: ['Male', 'Female'],
          selectedOption: selectedGender,
          onChanged: (value) {
            setState(() {
              selectedGender = value!;
            });
          },
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('preferred-language'),
          options: ['Arabic', 'English'],
          selectedOption: selectedLanguage,
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
          },
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
        CustomTextField(
          controller: confirmPasswordController,
          obscureText: true,
          hint: AppLocalizations.of(context).translate('confirm-password'),
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
        style: TextStyles.footnote.copyWith(height: 2.5),
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

class CustomSegmentedButton extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String?> onChanged;

  const CustomSegmentedButton({
    Key? key,
    required this.label,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.footnote.copyWith(color: theme.primary[600]),
        ),
        verticalSpace(Spacing.points8),
        Container(
          width: MediaQuery.of(context).size.width,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ToggleButtons(
                renderBorder: false,
                constraints: BoxConstraints.expand(
                  width: (constraints.maxWidth - (options.length - 1)) /
                      options.length,
                ),
                borderRadius: BorderRadius.circular(5),
                children: options
                    .map((option) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(option),
                        ))
                    .toList(),
                isSelected: options.map((e) => e == selectedOption).toList(),
                onPressed: (int index) {
                  onChanged(options[index]);
                },
                selectedBorderColor: theme.primary[600],
                selectedColor: theme.grey[50],
                fillColor: theme.primary[600],
                color: theme.primary[600],
              );
            },
          ),
        ),
      ],
    );
  }
}
