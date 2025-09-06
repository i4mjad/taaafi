import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/groups_main_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';

// Shorebird update imports
import 'package:reboot_app_3/features/home/presentation/home/widgets/shorebird_update_widget.dart';

class GroupsOnboardingScreen extends ConsumerWidget {
  const GroupsOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final shorebirdUpdateState = ref.watch(shorebirdUpdateProvider);

    // Check if Shorebird update requires blocking the entire screen
    final shouldBlockForShorebird =
        _shouldBlockForShorebirdUpdate(shorebirdUpdateState.status);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          // Priority 1: Check if Shorebird update requires blocking (highest priority)
          if (shouldBlockForShorebird) {
            return const ShorebirdUpdateBlockingWidget();
          }

          // Priority 2: Check account status
          switch (accountStatus) {
            case AccountStatus.loading:
              return const Center(child: Spinner());
            case AccountStatus.needCompleteRegistration:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CompleteRegistrationBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needConfirmDetails:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmDetailsBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needEmailVerification:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmEmailBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.pendingDeletion:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AccountActionBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.ok:
              // Always show the groups main screen, it will handle different states
              return const GroupsMainScreen();
          }
        },
      ),
    );
  }

  /// Determines if Shorebird update status should block the entire screen
  bool _shouldBlockForShorebirdUpdate(AppUpdateStatus status) {
    return status == AppUpdateStatus.available ||
        status == AppUpdateStatus.downloading ||
        status == AppUpdateStatus.completed;
  }
}
