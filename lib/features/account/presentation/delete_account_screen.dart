import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'delete-account', true, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('delete-account-info'),
                style: TextStyles.body,
              ),
              verticalSpace(Spacing.points8),
              WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.primary[600]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnboardingSection(
                      icon: LucideIcons.userX,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-data'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-data-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.fileStack,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-followups'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-followups-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.heart,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-emotions'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-emotions-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.activity,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-activities'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-activities-desc'),
                    ),
                  ],
                ),
              ),
              verticalSpace(Spacing.points16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('delete-account-warning'),
                    style: TextStyles.body.copyWith(
                        color: theme.error[600], fontWeight: FontWeight.bold),
                  ),
                  verticalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context).translate('relogin-required'),
                    style: TextStyles.small,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              verticalSpace(Spacing.points16),
              ReLoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingSection extends ConsumerWidget {
  const OnboardingSection(
      {super.key,
      required this.icon,
      required this.title,
      required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      padding: EdgeInsets.only(right: 16, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.error[600],
            weight: 100,
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.h6.copyWith(
                    color: theme.error[600],
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text(
                  description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[900],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ReLoginForm extends ConsumerStatefulWidget {
  const ReLoginForm({super.key});

  @override
  _ReLoginFormState createState() => _ReLoginFormState();
}

class _ReLoginFormState extends ConsumerState<ReLoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final authService = ref.watch(authServiceProvider);
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);

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
              return null;
            },
          ),
          verticalSpace(Spacing.points8),
          CustomTextField(
            controller: passwordController,
            obscureText: true,
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
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () async {
              final email = emailController.value.text;
              final password = passwordController.value.text;

              if (_formKey.currentState!.validate()) {
                final result = await authService.reSignInWithEmail(
                  context,
                  email,
                  password,
                );
                if (result) {
                  HapticFeedback.mediumImpact();
                  //TODO: invalidate all providers
                  await userProfileNotifier.handleUserDeletion();
                  context.goNamed(RouteNames.onboarding.name);
                  getSuccessSnackBar(context, 'account-deleted');
                }
              }
            },
            child: WidgetsContainer(
              backgroundColor: theme.error[600],
              width: MediaQuery.of(context).size.width - 32,
              padding: EdgeInsets.all(16),
              // boxShadow: Shadows.mainShadows,
              // borderRadius: BorderRadius.circular(10.5),
              borderSide: BorderSide(width: 0, color: theme.error[900]!),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('delete-account'),
                    style: TextStyles.footnoteSelected
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('or-relogin-with'),
            style: TextStyles.caption.copyWith(color: theme.primary[600]),
          ),
          verticalSpace(Spacing.points12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await authService.reSignInWithApple(context);
                  await userProfileNotifier.handleUserDeletion();
                  context.goNamed(RouteNames.onboarding.name);
                  getSuccessSnackBar(context, 'account-deleted');
                },
                child: Container(
                  height: 60,
                  width: 60,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: Shadows.mainShadows,
                      border: Border.all(
                        color: theme.grey[600]!,
                        width: 0.25,
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
                  HapticFeedback.mediumImpact();
                  await authService.reSignInWithGoogle(context);
                  await userProfileNotifier.handleUserDeletion();
                  context.goNamed(RouteNames.onboarding.name);
                  getSuccessSnackBar(context, 'account-deleted');
                },
                child: Container(
                  height: 60,
                  width: 60,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: Shadows.mainShadows,
                      border: Border.all(
                        color: theme.grey[600]!,
                        width: 0.25,
                      )),
                  child: SvgPicture.asset(
                    'asset/icons/google-icon.svg',
                    semanticsLabel: 'Google Logo',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
