import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/app_regex.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CustomThemeInherited.of(context);
    final authRepository = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: appBar(context, ref, 'forget-password', true),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                controller: emailController,
                hint: AppLocalizations.of(context).translate('email'),
                prefixIcon: LucideIcons.mail,
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('cant-be-empty');
                  } else if (!AppRegex.isEmailValid(value)) {
                    return AppLocalizations.of(context)
                        .translate('invalid-email');
                  }
                  return null;
                },
              ),
              verticalSpace(Spacing.points32),
              GestureDetector(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    await authRepository.sendForgotPasswordLink(
                        context, emailController.value.text);
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
                        AppLocalizations.of(context)
                            .translate('send-reset-password-link'),
                        style: TextStyles.footnoteSelected
                            .copyWith(color: theme.grey[50]),
                      ),
                    ],
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
