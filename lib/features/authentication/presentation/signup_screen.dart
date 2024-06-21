import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
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
      appBar: appBar(context, ref, null, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // verticalSpace(Spacing.points40),
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
  final startingDateController = TextEditingController();
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

  Future<void> _selectDob(BuildContext context, String language) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = getDisplayDate(picked, language);
      });
    }
  }

  Future<void> _selectStartingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          startingDateController.text =
              getDisplayDateTime(pickedDateTime, language);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = CustomThemeInherited.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextField(
              controller: nameController,
              hint: AppLocalizations.of(context).translate('first-name'),
              prefixIcon: LucideIcons.user,
              inputType: TextInputType.name,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
            GestureDetector(
              onTap: () => _selectDob(context, locale!.languageCode),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: dobController,
                  hint: AppLocalizations.of(context).translate('date-of-birth'),
                  prefixIcon: LucideIcons.calendar,
                  inputType: TextInputType.datetime,
                  width: MediaQuery.of(context).size.width / 2 - (16 + 2),
                ),
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        CustomTextField(
          controller: emailController,
          hint: AppLocalizations.of(context).translate('email'),
          prefixIcon: LucideIcons.mail,
          inputType: TextInputType.emailAddress,
        ),
        verticalSpace(Spacing.points8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextField(
              controller: passwordController,
              obscureText: true,
              hint: AppLocalizations.of(context).translate('password'),
              prefixIcon: LucideIcons.lock,
              inputType: TextInputType.visiblePassword,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
            verticalSpace(Spacing.points8),
            CustomTextField(
              controller: confirmPasswordController,
              obscureText: true,
              hint: AppLocalizations.of(context).translate('repeat-password'),
              prefixIcon: LucideIcons.lock,
              inputType: TextInputType.visiblePassword,
              width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('gender'),
          options: [
            AppLocalizations.of(context).translate('male'),
            AppLocalizations.of(context).translate('female')
          ],
          selectedOption: selectedGender,
          onChanged: (value) {
            setState(() {
              selectedGender = value!;
            });
          },
        ),
        verticalSpace(Spacing.points8),
        CustomSegmentedButton(
          label: AppLocalizations.of(context).translate('preferred-language'),
          options: [
            'العربية',
            'English',
          ],
          selectedOption: selectedLanguage,
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
          },
        ),
        verticalSpace(Spacing.points16),
        Text(
          'متابعة التعافي',
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points8),
        Text(
          'متى تريد البدء في متابعة تعافيك؟التاريخ الذي ستقوم باختياره، سنقوم ببدء العد منه',
          style: TextStyles.footnote.copyWith(color: theme.grey[600]),
        ),
        verticalSpace(Spacing.points8),
        GestureDetector(
          onTap: () => _selectStartingDate(context, locale!.languageCode),
          child: AbsorbPointer(
            child: CustomTextField(
              controller: startingDateController,
              hint: AppLocalizations.of(context).translate('date-of-birth'),
              prefixIcon: LucideIcons.calendar,
              inputType: TextInputType.datetime,
              // width: MediaQuery.of(context).size.width / 2 - (16 + 2),
            ),
          ),
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
  final double? width;

  const CustomTextField({
    Key? key,
    this.borderRadius,
    this.borderSide,
    this.width,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: TextStyles.footnote,
        ),
        verticalSpace(Spacing.points4),
        Container(
          width: width ?? MediaQuery.of(context).size.width - 32,
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
                    color: theme.primary[100]!,
                    width: 1,
                  ),
            ),
          ),
          child: TextField(
            enabled: true,
            controller: controller,
            textCapitalization: textCapitalization,
            maxLength: 100,
            maxLines: 1,
            obscureText: obscureText,
            keyboardType: inputType,
            textAlign: TextAlign.start,
            style: TextStyles.footnote,
            decoration: InputDecoration(
              prefixIcon: Icon(prefixIcon),
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 16, bottom: 16),
            ),
          ),
        ),
      ],
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
                renderBorder: true,
                constraints: BoxConstraints.expand(
                  width: (constraints.maxWidth - (options.length + 2)) /
                      options.length,
                ),
                borderRadius: BorderRadius.circular(5),
                children: options
                    .map((option) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            option,
                            style: TextStyles.body,
                          ),
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
