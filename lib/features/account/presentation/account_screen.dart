import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/app_review/app_review.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_cta_button.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/account/data/models/user_profile.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/account/presentation/contact_us_modal.dart';

import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/account/data/app_features_config.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/plus/presentation/widgets/subscription_card.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/features/plus/presentation/feature_suggestion_modal.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

import 'package:shorebird_code_push/shorebird_code_push.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthService authService = ref.watch(authServiceProvider);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final accountStatus = ref.watch(accountStatusProvider);
    final showMainContent = accountStatus == AccountStatus.ok;
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final theme = AppTheme.of(context);
    final customTheme = ref.watch(customThemeProvider);
    return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, 'account', false, true, actions: [
          PremiumCtaAppBarIcon(),
        ]),
        body: userDocAsync.when(
            loading: () => const Center(child: Spinner()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (_) => userProfileState.when(
                  data: (userProfile) {
                    // Handle case where userProfile is null (e.g., during account deletion)
                    if (userProfile == null) {
                      return const CompleteRegistrationBanner();
                    }

                    return Container(
                      width: MediaQuery.of(context).size.width,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (accountStatus == AccountStatus.loading)
                                Center(
                                  child: Spinner(),
                                ),

                              // If account deletion is pending, show only the banner
                              if (accountStatus ==
                                  AccountStatus.pendingDeletion)
                                const AccountActionBanner(isFullScreen: true),

                              // Show other banners and content only if not pending deletion
                              if (accountStatus !=
                                  AccountStatus.pendingDeletion) ...[
                                if (!showMainContent &&
                                    accountStatus ==
                                        AccountStatus.needCompleteRegistration)
                                  const CompleteRegistrationBanner(),
                                if (!showMainContent &&
                                    accountStatus ==
                                        AccountStatus.needConfirmDetails)
                                  const ConfirmDetailsBanner(),
                                if (!showMainContent &&
                                    accountStatus ==
                                        AccountStatus.needEmailVerification)
                                  const ConfirmEmailBanner(),

                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    context
                                        .pushNamed(RouteNames.userProfile.name);
                                  },
                                  child: UserDetailsWidget(
                                    userProfile,
                                    // onAvatarTap: (hasProfileImage) =>
                                    //     _showProfileImageOptions(
                                    //         context, ref, hasProfileImage),
                                  ),
                                ),
                                verticalSpace(Spacing.points24),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('appearance'),
                                  style: TextStyles.h6,
                                ),
                                verticalSpace(Spacing.points16),
                                // Color Scheme Section
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('color-scheme'),
                                  style: TextStyles.body.copyWith(
                                    color: theme.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                verticalSpace(Spacing.points4),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('color-scheme-description'),
                                  style: TextStyles.small.copyWith(
                                    color: theme.grey[500],
                                    height: 1.4,
                                  ),
                                ),
                                verticalSpace(Spacing.points12),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final themeNotifier =
                                        ref.watch(customThemeProvider.notifier);
                                    final isDarkMode =
                                        themeNotifier.darkTheme == true;

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // Light Mode Card
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            if (isDarkMode) {
                                              themeNotifier.toggleTheme();
                                            }
                                          },
                                          child: WidgetsContainer(
                                            width: 80,
                                            height: 80,
                                            padding: const EdgeInsets.all(12),
                                            backgroundColor: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: !isDarkMode
                                                  ? theme.primary[600]!
                                                  : theme.grey[300]!,
                                              width: !isDarkMode ? 2 : 1,
                                            ),
                                            cornerSmoothing: 1,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  LucideIcons.sun,
                                                  size: 20,
                                                  color: !isDarkMode
                                                      ? theme.primary[600]
                                                      : Colors.grey[600],
                                                ),
                                                verticalSpace(Spacing.points4),
                                                Text(
                                                  AppLocalizations.of(context)
                                                      .translate('light'),
                                                  style:
                                                      TextStyles.small.copyWith(
                                                    color: !isDarkMode
                                                        ? theme.primary[700]
                                                        : Colors.grey[700],
                                                    fontWeight: !isDarkMode
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        horizontalSpace(Spacing.points12),
                                        // Dark Mode Card
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            if (!isDarkMode) {
                                              themeNotifier.toggleTheme();
                                            }
                                          },
                                          child: WidgetsContainer(
                                            width: 80,
                                            height: 80,
                                            padding: const EdgeInsets.all(12),
                                            backgroundColor: Color(0xFF1A1A1A),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: isDarkMode
                                                  ? theme.primary[600]!
                                                  : Colors.grey[300]!,
                                              width: isDarkMode ? 2 : 1,
                                            ),
                                            cornerSmoothing: 1,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  LucideIcons.moon,
                                                  size: 20,
                                                  color: isDarkMode
                                                      ? theme.primary[400]
                                                      : Colors.grey[400],
                                                ),
                                                verticalSpace(Spacing.points4),
                                                Text(
                                                  AppLocalizations.of(context)
                                                      .translate('dark'),
                                                  style:
                                                      TextStyles.small.copyWith(
                                                    color: isDarkMode
                                                        ? theme.primary[300]
                                                        : Colors.grey[400],
                                                    fontWeight: isDarkMode
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                verticalSpace(Spacing.points16),
                                // Language Section
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('change-lang'),
                                  style: TextStyles.body.copyWith(
                                    color: theme.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                verticalSpace(Spacing.points8),
                                CustomSegmentedButton(
                                  options: [
                                    SegmentedButtonOption(
                                        value: 'arabic',
                                        translationKey: 'arabic'),
                                    SegmentedButtonOption(
                                        value: 'english',
                                        translationKey: 'english'),
                                  ],
                                  selectedOption:
                                      _getSelectedLocale(context, ref),
                                  onChanged: (value) {
                                    _updateThelocale(value, ref);
                                  },
                                ),
                                verticalSpace(Spacing.points24),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('user'),
                                  style: TextStyles.h6,
                                ),
                                verticalSpace(Spacing.points8),
                                if (showMainContent)
                                  GestureDetector(
                                    onTap: () {
                                      context.pushNamed(
                                          RouteNames.userReports.name);
                                    },
                                    child: SettingsButton(
                                      icon: LucideIcons.fileText,
                                      textKey: 'my-reports',
                                    ),
                                  ),
                                verticalSpace(Spacing.points8),
                                FeatureAccessGuard(
                                  featureUniqueName:
                                      AppFeaturesConfig.contactAdmin,
                                  onTap: () =>
                                      _showContactUsModal(context, ref),
                                  customBanMessage: AppLocalizations.of(context)
                                      .translate('contact-support-restricted'),
                                  child: SettingsButton(
                                    icon: LucideIcons.helpCircle,
                                    textKey: 'contact-support-team',
                                  ),
                                ),
                                verticalSpace(Spacing.points8),
                                if (showMainContent)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final hasActiveSubscription = ref
                                          .watch(hasActiveSubscriptionProvider);

                                      if (hasActiveSubscription) {
                                        // Show feature suggestion for Plus users
                                        return GestureDetector(
                                          onTap: () =>
                                              _showFeatureSuggestionModal(
                                                  context, ref),
                                          child: SettingsButton(
                                            icon: LucideIcons.lightbulb,
                                            textKey: 'suggest-feature',
                                          ),
                                        );
                                      } else {
                                        // Show premium upgrade modal for free users
                                        return GestureDetector(
                                          onTap: () => _showSubscriptionModal(
                                              context, ref),
                                          child: SettingsButton(
                                            icon: LucideIcons.star,
                                            textKey:
                                                'suggest-feature-plus-only',
                                            type: 'app',
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                verticalSpace(Spacing.points8),
                                SettingsButton(
                                  icon: LucideIcons.logOut,
                                  textKey: 'log-out',
                                  action: () async {
                                    await authService.signOut(context, ref);
                                    getSuccessSnackBar(
                                        context, 'logged-out-successfully');
                                  },
                                ),
                                verticalSpace(Spacing.points8),
                                GestureDetector(
                                  onTap: () async {
                                    unawaited(ref
                                        .read(analyticsFacadeProvider)
                                        .trackUserDeleteAccount());

                                    context
                                        .goNamed(RouteNames.accountDelete.name);
                                  },
                                  child: SettingsButton(
                                    icon: LucideIcons.userX,
                                    textKey: 'delete-my-account',
                                    type: 'error',
                                  ),
                                ),
                                verticalSpace(Spacing.points8),
                                // Manual Update Check
                                SettingsButton(
                                  icon: LucideIcons.download,
                                  textKey: 'check-for-updates',
                                  type: 'app',
                                  action: () {
                                    _showUpdateCheckModal(context, ref);
                                  },
                                ),
                                verticalSpace(Spacing.points8),
                                // Contact Us and Rate App in one row
                                Row(
                                  children: [
                                    Expanded(
                                      child: SettingsButton(
                                        icon: LucideIcons.messageCircle,
                                        textKey:
                                            'contact-us-through-this-channels',
                                        action: () async {
                                          await ref
                                              .read(urlLauncherProvider)
                                              .launch(Uri.parse(
                                                  'https://wa.me/96876691799'));
                                        },
                                      ),
                                    ),
                                    horizontalSpace(Spacing.points8),
                                    Expanded(
                                      child: SettingsButton(
                                        icon: LucideIcons.star,
                                        textKey: 'rate-app',
                                        action: () async {
                                          await ref
                                              .read(inAppRatingServiceProvider)
                                              .requestReview(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                verticalSpace(Spacing.points24),
                                // Version at the bottom without container
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      launchUrl(
                                          Uri.parse('https://ta3afi.app'));
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate('version-number'),
                                      style: TextStyles.caption.copyWith(
                                        color: theme.grey[600],
                                      ),
                                    ),
                                  ),
                                ),

                                verticalSpace(Spacing.points12),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  error: (error, stackTrace) =>
                      Center(child: Text('Error: $error')),
                  loading: () => Center(child: Spinner()),
                )));
  }

  void _showContactUsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContactUsModal(),
    );
  }

  void _showFeatureSuggestionModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeatureSuggestionModal(),
    );
  }

  void _showSubscriptionModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaaafiPlusSubscriptionScreen(),
    );
  }

  SegmentedButtonOption _getSelectedLocale(
      BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    if (locale?.languageCode == 'ar') {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    } else if (locale?.languageCode == 'en') {
      return SegmentedButtonOption(value: 'english', translationKey: 'english');
    } else {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    }
  }

  void _updateThelocale(SegmentedButtonOption value, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final localeNotifier = ref.watch(localeNotifierProvider.notifier);

    if (value.value == "arabic" && locale?.languageCode == 'en') {
      localeNotifier.toggleLocale();
    } else if (value.value == "english" && locale?.languageCode == 'ar') {
      localeNotifier.toggleLocale();
    }
  }

  void _showUpdateCheckModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UpdateCheckModal(),
    );
  }

  // Temporarily disabled profile image changing functionality
  // void _showProfileImageOptions(
  //     BuildContext context, WidgetRef ref, bool hasProfileImage) {
  //   final theme = AppTheme.of(context);
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => Container(
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: theme.backgroundColor,
  //         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           // Handle bar
  //           Container(
  //             width: 40,
  //             height: 4,
  //             decoration: BoxDecoration(
  //               color: theme.grey[300],
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           verticalSpace(Spacing.points16),

  //           // Title
  //           Text(
  //             AppLocalizations.of(context).translate('change-profile-picture'),
  //             style: TextStyles.h6.copyWith(color: theme.grey[900]),
  //           ),
  //           verticalSpace(Spacing.points16),

  //           // Change picture option
  //           ListTile(
  //             leading: Icon(
  //               LucideIcons.camera,
  //               color: theme.primary[600],
  //             ),
  //             title: Text(
  //               AppLocalizations.of(context)
  //                   .translate('change-profile-picture'),
  //               style: TextStyles.body.copyWith(color: theme.grey[900]),
  //             ),
  //             onTap: () async {
  //               Navigator.of(context).pop();
  //               await ref
  //                   .read(profileImageServiceProvider)
  //                   .changeProfileImage(context);
  //             },
  //           ),

  //           // Remove picture option (only show if user has a profile image)
  //           if (hasProfileImage) ...[
  //             ListTile(
  //               leading: Icon(
  //                 LucideIcons.trash2,
  //                 color: theme.error[600],
  //               ),
  //               title: Text(
  //                 AppLocalizations.of(context)
  //                     .translate('remove-profile-picture'),
  //                 style: TextStyles.body.copyWith(color: theme.error[600]),
  //               ),
  //               onTap: () async {
  //                 Navigator.of(context).pop();
  //                 await ref
  //                     .read(profileImageServiceProvider)
  //                     .removeProfileImage(context);
  //               },
  //             ),
  //           ],

  //           verticalSpace(Spacing.points16),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class UiAndLanguageSettings extends ConsumerWidget {
  const UiAndLanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(builder: (context, ref, child) {
      final theme = AppTheme.of(context);
      final themeNotifier = ref.watch(customThemeProvider.notifier);
      return Container(
        color: theme.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(Spacing.points16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context).translate('ui-settings'),
                      style: TextStyles.h4.copyWith(
                        color: theme.grey[900],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(LucideIcons.xCircle),
                  )
                ],
              ),
              verticalSpace(Spacing.points24),
              Text(
                AppLocalizations.of(context).translate('night-mode'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points12),
              GestureDetector(
                onTap: () {
                  themeNotifier.toggleTheme();
                  Navigator.of(context).pop();
                },
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  borderRadius: BorderRadius.circular(10.5),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.16),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: Offset(
                        0,
                        1,
                      ),
                    ),
                  ],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.moon),
                      horizontalSpace(Spacing.points12),
                      Text(
                        themeNotifier.darkTheme == true
                            ? AppLocalizations.of(context).translate('off')
                            : AppLocalizations.of(context).translate('on'),
                        style: TextStyles.footnoteSelected
                            .copyWith(color: theme.grey[900], height: 2),
                      ),
                    ],
                  ),
                ),
              ),
              verticalSpace(Spacing.points24),
              Text(
                AppLocalizations.of(context).translate('change-lang'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points8),
              CustomSegmentedButton(
                options: [
                  SegmentedButtonOption(
                      value: 'arabic', translationKey: 'arabic'),
                  SegmentedButtonOption(
                      value: 'english', translationKey: 'english'),
                ],
                selectedOption: _getSelectedLocale(context, ref),
                onChanged: (value) {
                  _updateThelocale(value, ref);
                  Navigator.of(context).pop();
                },
              ),
              verticalSpace(Spacing.points16),
            ],
          ),
        ),
      );
    });
  }

  _getSelectedLocale(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    if (locale?.languageCode == 'ar') {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    } else if (locale?.languageCode == 'en') {
      return SegmentedButtonOption(value: 'english', translationKey: 'english');
    } else {
      return SegmentedButtonOption(value: 'arabic', translationKey: 'arabic');
    }
  }

  _updateThelocale(SegmentedButtonOption value, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final localeNotifier = ref.watch(localeNotifierProvider.notifier);

    if (value.value == "arabic" && locale?.languageCode == 'en') {
      localeNotifier.toggleLocale();
    } else if (value.value == "english" && locale?.languageCode == 'ar') {
      localeNotifier.toggleLocale();
    }
  }
}

class SettingsButton extends StatelessWidget {
  final IconData icon;
  final String textKey;
  final String? type;
  final VoidCallback? action;
  const SettingsButton(
      {super.key,
      required this.icon,
      required this.textKey,
      this.type,
      this.action});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: WidgetsContainer(
          padding: EdgeInsets.all(12),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(
              color: type == 'error' ? theme.error[600]! : theme.grey[600]!,
              width: 0.5),
          borderRadius: BorderRadius.circular(10.5),
          boxShadow: Shadows.mainShadows,
          child: Row(
            children: [
              Icon(
                icon,
                color: type == 'error' ? theme.error[600]! : theme.grey[900],
              ),
              horizontalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context).translate(textKey),
                style: TextStyles.small
                    .copyWith(color: _getTextColor(type, theme)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getTextColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'app':
        return theme.primary[600] as Color;
      case 'error':
        return theme.error[600] as Color;
      default:
        return theme.grey[900] as Color;
    }
  }
}

class UserDetailsWidget extends ConsumerWidget {
  const UserDetailsWidget(
    this.userProfile, {
    super.key,
    this.onAvatarTap,
  });
  final UserProfile userProfile;
  final Function(bool hasProfileImage)? onAvatarTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final currentUser = ref.watch(userNotifierProvider);
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: WidgetsContainer(
        width: MediaQuery.of(context).size.width - 32,
        padding: EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
        cornerSmoothing: 1,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                currentUser.when(
                  data: (user) {
                    final hasProfileImage =
                        user?.photoURL != null && user!.photoURL!.isNotEmpty;

                    return CircleAvatar(
                      backgroundColor: theme.primary[50],
                      backgroundImage:
                          hasProfileImage ? NetworkImage(user.photoURL!) : null,
                      child: hasProfileImage
                          ? null
                          : Icon(
                              LucideIcons.user,
                              color: theme.primary[900],
                            ),
                    );
                    // Temporarily disabled interactive avatar with camera icon
                    // return GestureDetector(
                    //   onTap: onAvatarTap != null
                    //       ? () => onAvatarTap!(hasProfileImage)
                    //       : null,
                    //   child: Stack(
                    //     children: [
                    //       CircleAvatar(
                    //         backgroundColor: theme.primary[50],
                    //         backgroundImage: hasProfileImage
                    //             ? NetworkImage(user.photoURL!)
                    //             : null,
                    //         child: hasProfileImage
                    //             ? null
                    //             : Icon(
                    //                 LucideIcons.user,
                    //                 color: theme.primary[900],
                    //               ),
                    //       ),
                    //       Positioned(
                    //         bottom: -2,
                    //         right: -2,
                    //         child: Container(
                    //           padding: const EdgeInsets.all(4),
                    //           decoration: BoxDecoration(
                    //             color: theme.primary[600],
                    //             shape: BoxShape.circle,
                    //             border: Border.all(
                    //               color: theme.backgroundColor,
                    //               width: 2,
                    //             ),
                    //           ),
                    //           child: Icon(
                    //             LucideIcons.camera,
                    //             size: 12,
                    //             color: Colors.white,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // );
                  },
                  loading: () => CircleAvatar(
                    backgroundColor: theme.primary[50],
                    child: Icon(
                      LucideIcons.user,
                      color: theme.primary[900],
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    backgroundColor: theme.primary[50],
                    child: Icon(
                      LucideIcons.user,
                      color: theme.primary[900],
                    ),
                  ),
                ),
                verticalSpace(Spacing.points12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.displayName,
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[900],
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                          userProfile.email,
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                          userProfile.age.toString() +
                              " " +
                              AppLocalizations.of(context).translate('years'),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        // Enhanced subscription status with more details
                        subscriptionAsync.when(
                          data: (subscription) {
                            final isPlus = subscription.status ==
                                    SubscriptionStatus.plus &&
                                subscription.isActive;
                            final hasExpiration =
                                subscription.expirationDate != null;
                            final activeFeatures = subscription
                                    .customerInfo?.entitlements.active.length ??
                                0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main subscription badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPlus
                                        ? theme.primary[100]
                                        : theme.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isPlus
                                          ? theme.primary[300]!
                                          : theme.grey[300]!,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPlus
                                            ? LucideIcons.star
                                            : LucideIcons.user,
                                        size: 14,
                                        color: isPlus
                                            ? theme.primary[600]
                                            : theme.grey[600],
                                      ),
                                      horizontalSpace(Spacing.points4),
                                      Text(
                                        isPlus
                                            ? AppLocalizations.of(context)
                                                .translate('plus-member')
                                            : AppLocalizations.of(context)
                                                .translate('free-plan'),
                                        style: TextStyles.small.copyWith(
                                          color: isPlus
                                              ? theme.primary[700]
                                              : theme.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Additional details for Plus members
                                if (isPlus) ...[
                                  verticalSpace(Spacing.points4),
                                  Row(
                                    children: [
                                      // Expiration info
                                      if (hasExpiration) ...[
                                        Icon(
                                          LucideIcons.calendar,
                                          size: 12,
                                          color: theme.grey[500],
                                        ),
                                        horizontalSpace(Spacing.points4),
                                        Text(
                                          AppLocalizations.of(context)
                                                  .translate('expires') +
                                              ' ' +
                                              _formatShortDate(
                                                  subscription.expirationDate!,
                                                  locale?.languageCode ?? 'en'),
                                          style: TextStyles.small.copyWith(
                                            color: theme.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      if (hasExpiration &&
                                          activeFeatures > 0) ...[
                                        horizontalSpace(Spacing.points8),
                                        Container(
                                          width: 2,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: theme.grey[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        horizontalSpace(Spacing.points8),
                                      ],
                                      // Active features count
                                      if (activeFeatures > 0) ...[
                                        Icon(
                                          LucideIcons.checkCircle,
                                          size: 12,
                                          color: theme.success[600],
                                        ),
                                        horizontalSpace(Spacing.points4),
                                        Text(
                                          '$activeFeatures ${AppLocalizations.of(context).translate('features-active')}',
                                          style: TextStyles.small.copyWith(
                                            color: theme.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: Spinner(strokeWidth: 1.5),
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('loading'),
                                  style: TextStyles.small.copyWith(
                                    color: theme.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Icon(
                Directionality.of(context).toString().contains('rtl')
                    ? LucideIcons.chevronLeft
                    : LucideIcons.chevronRight,
                color: theme.grey[600]),
          ],
        ),
      ),
    );
  }

  /// Helper method to format short date for compact display
  String _formatShortDate(dynamic date, String language) {
    try {
      DateTime dateTime;

      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return '';
      }

      // Format as "Jul 31" or short month format
      return DateFormat('MMM dd', language == 'ar' ? 'ar' : 'en')
          .format(dateTime);
    } catch (e) {
      return '';
    }
  }
}

class UpdateCheckModal extends ConsumerStatefulWidget {
  const UpdateCheckModal({super.key});

  @override
  ConsumerState<UpdateCheckModal> createState() => _UpdateCheckModalState();
}

class _UpdateCheckModalState extends ConsumerState<UpdateCheckModal> {
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _updateAvailable = false;
  bool _updateCompleted = false;
  double _downloadProgress = 0.0;
  String? _error;

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
      _error = null;
      _updateAvailable = false;
      _updateCompleted = false;
    });

    try {
      final updateStatus = await _updater.checkForUpdate();

      if (mounted) {
        setState(() {
          _isChecking = false;
          _updateAvailable = updateStatus == UpdateStatus.outdated;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _downloadUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _error = null;
    });

    // Simulate progress
    for (int i = 0; i <= 100; i += 5) {
      if (mounted) {
        setState(() {
          _downloadProgress = i.toDouble();
        });
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    try {
      await _updater.update();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _updateCompleted = true;
          _downloadProgress = 100.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          verticalSpace(Spacing.points20),

          // Title
          Text(
            AppLocalizations.of(context).translate('check-for-updates'),
            style: TextStyles.h5.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points24),

          // Content based on state
          if (_isChecking) _buildCheckingContent(),
          if (!_isChecking && _error != null) _buildErrorContent(),
          if (!_isChecking &&
              _error == null &&
              !_updateAvailable &&
              !_updateCompleted)
            _buildUpToDateContent(),
          if (_updateAvailable && !_isDownloading && !_updateCompleted)
            _buildUpdateAvailableContent(),
          if (_isDownloading) _buildDownloadingContent(),
          if (_updateCompleted) _buildCompletedContent(),

          verticalSpace(Spacing.points24),
        ],
      ),
    );
  }

  Widget _buildCheckingContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        const Spinner(),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('checking-for-updates'),
          style: TextStyles.body.copyWith(color: theme.grey[700]),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Icon(
          LucideIcons.alertCircle,
          size: 48,
          color: theme.error[600],
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('update-check-failed'),
          style: TextStyles.h6.copyWith(color: theme.error[700]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Text(
          _error ??
              AppLocalizations.of(context).translate('something-went-wrong'),
          style: TextStyles.small.copyWith(color: theme.grey[600]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _checkForUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('try-again'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpToDateContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Icon(
          LucideIcons.checkCircle,
          size: 48,
          color: theme.success[600],
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('up-to-date'),
          style: TextStyles.h6.copyWith(color: theme.success[700]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('up-to-date-message'),
          style: TextStyles.body.copyWith(color: theme.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpdateAvailableContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Icon(
          LucideIcons.download,
          size: 48,
          color: theme.primary[600],
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('update-available'),
          style: TextStyles.h6.copyWith(color: theme.primary[700]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('update-available-message'),
          style: TextStyles.body.copyWith(color: theme.grey[600]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _downloadUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('update-button'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        const Spinner(),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('updating'),
          style: TextStyles.h6.copyWith(color: theme.primary[700]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _downloadProgress / 100,
            minHeight: 8,
            backgroundColor: theme.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary[600]!),
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          '${_downloadProgress.toStringAsFixed(0)}%',
          style: TextStyles.small.copyWith(color: theme.primary[700]),
        ),
      ],
    );
  }

  Widget _buildCompletedContent() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Icon(
          LucideIcons.checkCircle,
          size: 48,
          color: theme.success[600],
        ),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('update-complete'),
          style: TextStyles.h6.copyWith(color: theme.success[700]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate('update-complete-message'),
          style: TextStyles.body.copyWith(color: theme.grey[600]),
          textAlign: TextAlign.center,
        ),
        verticalSpace(Spacing.points20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // You can add restart functionality here if needed
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.success[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('done'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
