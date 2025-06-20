import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class OnBoardingScreen extends ConsumerWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        null,
        true,
        true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        'asset/illustrations/app-logo.png',
                        height: 125,
                        width: 125,
                      ),
                      verticalSpace(Spacing.points28),
                      Text(
                        AppLocalizations.of(context)
                            .translate('taaafi-platform'),
                        style: TextStyles.h2.copyWith(
                          color: theme.primary[600],
                        ),
                      ),
                      verticalSpace(Spacing.points28),
                      OnboardingSection(
                        icon: LucideIcons.lock,
                        title: AppLocalizations.of(context)
                            .translate('vault-title'),
                        description: AppLocalizations.of(context)
                            .translate('vault-description'),
                      ),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                        icon: LucideIcons.dumbbell,
                        title: AppLocalizations.of(context)
                            .translate('exercises-title'),
                        description: AppLocalizations.of(context)
                            .translate('exercises-description'),
                      ),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                        icon: LucideIcons.listChecks,
                        title: AppLocalizations.of(context)
                            .translate('lists-title'),
                        description: AppLocalizations.of(context)
                            .translate('lists-description'),
                      ),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                        icon: LucideIcons.bell,
                        title: AppLocalizations.of(context)
                            .translate('reminders-title'),
                        description: AppLocalizations.of(context)
                            .translate('reminders-description'),
                      ),
                      verticalSpace(Spacing.points24),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(analyticsFacadeProvider).trackOnboardingStart();
                  context.goNamed(RouteNames.login.name);
                },
                child: WidgetsContainer(
                  backgroundColor: theme.primary[600],
                  width: MediaQuery.of(context).size.width - 64,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('login'),
                      style: TextStyles.footnoteSelected.copyWith(
                        color: theme.grey[50],
                      ),
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
            color: theme.primary[600],
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
                    color: theme.primary[600],
                  ),
                ),
                verticalSpace(Spacing.points8),
                // Second text
                Text(
                  description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                    height: 1.5,
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
