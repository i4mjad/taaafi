import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/current_streaks_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calendar_section.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activities_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';

class CombinedTestScreen extends ConsumerWidget {
  const CombinedTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final showMainContent = accountStatus == AccountStatus.ok;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'about',
        false,
        true,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(child: Spinner());
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
            case AccountStatus.ok:
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(Spacing.points16),

                    // Vertical Colorful Cards
                    _buildVerticalCards(context, theme),
                    verticalSpace(Spacing.points16),

                    // Today's Tasks from Vault
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TodayTasksWidget(),
                    ),

                    // Current Streaks from Home
                    const CurrentStreaksSection(),
                    verticalSpace(Spacing.points16),

                    // Statistics from Home
                    const StatisticsSection(),
                    verticalSpace(Spacing.points16),

                    // Calendar from Home
                    const CalendarSection(),
                    verticalSpace(Spacing.points32),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildVerticalCards(BuildContext context, CustomThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: [
          _buildHorizontalCard(
            context,
            theme,
            LucideIcons.clipboardCheck,
            "activities",
            theme.primary[500]!,
            theme.primary[50]!,
            () => context.goNamed(RouteNames.activities.name),
          ),
          horizontalSpace(Spacing.points8),
          _buildHorizontalCard(
            context,
            theme,
            LucideIcons.lamp,
            "library",
            theme.secondary[500]!,
            theme.secondary[50]!,
            () => context.goNamed(RouteNames.library.name),
          ),
          horizontalSpace(Spacing.points8),
          _buildHorizontalCard(
            context,
            theme,
            LucideIcons.pencil,
            "diaries",
            theme.tint[500]!,
            theme.tint[50]!,
            () => context.goNamed(RouteNames.diaries.name),
          ),
          horizontalSpace(Spacing.points8),
          _buildHorizontalCard(
            context,
            theme,
            LucideIcons.bell,
            "notifications",
            theme.warn[500]!,
            theme.warn[50]!,
            () => context.goNamed(RouteNames.notifications.name),
          ),
          horizontalSpace(Spacing.points8),
          _buildHorizontalCard(
            context,
            theme,
            LucideIcons.settings,
            "settings",
            theme.grey[500]!,
            theme.grey[50]!,
            () => context.goNamed(RouteNames.vaultSettings.name),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    CustomThemeData theme,
    IconData icon,
    String textKey,
    Color iconColor,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        width: 70,
        height: 70,
        padding: EdgeInsets.all(8),
        backgroundColor: backgroundColor,
        borderSide: BorderSide(color: iconColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
