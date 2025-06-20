import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activities_screen.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/vault_info_bottom_sheet.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final showMainContent = accountStatus == AccountStatus.ok;
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'vault',
        false,
        false,
        actions: showMainContent
            ? [
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const VaultInfoBottomSheet(),
                    );
                  },
                  icon: Icon(LucideIcons.badgeInfo),
                )
              ]
            : null,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => Column(
          children: [
            // Action banners (shown when account is NOT OK)
            if (accountStatus == AccountStatus.needCompleteRegistration)
              const CompleteRegistrationBanner(),
            if (accountStatus == AccountStatus.needConfirmDetails)
              const ConfirmDetailsBanner(),

            // Main vault content only when account is OK
            if (showMainContent) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TodayTasksWidget(),
                        // Add other scrollable content here
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate("quick-access"),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.goNamed(RouteNames.activities.name);
                            },
                            child: WidgetsContainer(
                              padding: EdgeInsets.all(12),
                              backgroundColor: theme.backgroundColor,
                              borderSide:
                                  BorderSide(color: theme.grey[100]!, width: 1),
                              boxShadow: Shadows.mainShadows,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.clipboardCheck,
                                    size: 18,
                                    color: theme.primary[900],
                                  ),
                                  horizontalSpace(Spacing.points8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate("activities"),
                                    style: TextStyles.footnote
                                        .copyWith(color: theme.grey[900]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.goNamed(RouteNames.library.name);
                            },
                            child: WidgetsContainer(
                              padding: EdgeInsets.all(12),
                              backgroundColor: theme.backgroundColor,
                              borderSide:
                                  BorderSide(color: theme.grey[100]!, width: 1),
                              boxShadow: Shadows.mainShadows,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.lamp,
                                    size: 18,
                                    color: theme.primary[900],
                                  ),
                                  horizontalSpace(Spacing.points8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate("library"),
                                    style: TextStyles.footnote
                                        .copyWith(color: theme.grey[900]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.goNamed(RouteNames.diaries.name);
                            },
                            child: WidgetsContainer(
                              padding: EdgeInsets.all(12),
                              backgroundColor: theme.backgroundColor,
                              borderSide:
                                  BorderSide(color: theme.grey[100]!, width: 1),
                              boxShadow: Shadows.mainShadows,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.pencil,
                                    size: 18,
                                    color: theme.primary[900],
                                  ),
                                  horizontalSpace(Spacing.points8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate("diaries"),
                                    style: TextStyles.footnote
                                        .copyWith(color: theme.grey[900]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.goNamed(RouteNames.vaultSettings.name);
                            },
                            child: WidgetsContainer(
                              padding: EdgeInsets.all(12),
                              backgroundColor: theme.backgroundColor,
                              borderSide:
                                  BorderSide(color: theme.grey[100]!, width: 1),
                              boxShadow: Shadows.mainShadows,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.settings2,
                                    size: 18,
                                    color: theme.primary[900],
                                  ),
                                  horizontalSpace(Spacing.points8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate("settings"),
                                    style: TextStyles.footnote
                                        .copyWith(color: theme.grey[900]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
