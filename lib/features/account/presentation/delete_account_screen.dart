import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/account/presentation/account_deletion_loading_screen.dart';

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);

    // Screen accessible regardless of account status; banners shown at top

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
                    AppLocalizations.of(context)
                        .translate('delete-account-final-warning'),
                    style: TextStyles.small.copyWith(
                      height: 1.75,
                      color: theme.error[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              verticalSpace(Spacing.points24),

              // Simple delete button - no re-auth form
              Consumer(
                builder: (context, ref, child) {
                  return GestureDetector(
                    onTap: () {
                      _showDeleteConfirmationDialog(context);
                    },
                    child: WidgetsContainer(
                      backgroundColor: theme.error[600],
                      width: MediaQuery.of(context).size.width - 32,
                      padding: EdgeInsets.all(16),
                      borderSide:
                          BorderSide(width: 0, color: theme.error[900]!),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.userX,
                            color: Colors.white,
                            size: 20,
                          ),
                          horizontalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context)
                                .translate('delete-account'),
                            style: TextStyles.footnoteSelected
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final theme = AppTheme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              verticalSpace(Spacing.points24),

              // Icon and title
              Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.error[600],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('delete-account-confirmation-title'),
                      style: TextStyles.h5.copyWith(
                        color: theme.primary[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points16),

              // Message
              Text(
                AppLocalizations.of(context)
                    .translate('delete-account-confirmation-message'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.5,
                ),
              ),
              verticalSpace(Spacing.points32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: WidgetsContainer(
                        backgroundColor: theme.backgroundColor,
                        borderSide:
                            BorderSide(color: theme.grey[400]!, width: 1),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate('cancel'),
                            style: TextStyles.footnoteSelected.copyWith(
                              color: theme.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate directly to loading screen
                        final rootContext = rootNavigatorKey.currentContext;
                        if (rootContext != null && rootContext.mounted) {
                          Navigator.of(rootContext).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountDeletionLoadingScreen(),
                              settings: const RouteSettings(
                                  name: 'account-deletion-loading'),
                            ),
                          );
                        }
                      },
                      child: WidgetsContainer(
                        backgroundColor: theme.error[600],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('delete-account'),
                            style: TextStyles.footnoteSelected.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
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
